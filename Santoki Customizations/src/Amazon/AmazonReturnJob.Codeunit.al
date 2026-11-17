// The scheduled returns job: read new returns deliveries, check received returns, then build (and,
// if the marketplace says so, post) one returns journal per marketplace.
//
// Run it from the job queue once a day, or from the Amazon Returns page. Each delivery and each
// return is handled in its own transaction, so one bad row is marked Error and the rest carry on.
// Posting is all or nothing per marketplace.
//
// Only one run at a time. The job takes its own row ('RETURNS') in the Amazon Order Job Lock table,
// so it never blocks the order job, which uses the blank row.
codeunit 50206 "Amazon Return Job"
{
    trigger OnRun()
    begin
        if not TryTakeLock() then
            exit;

        ReadInbox();
        CheckReceivedReturns();
        PostReadyReturns();

        ReleaseLock();
    end;

    var
        AlreadyRunningMsg: Label 'Amazon returns are already being processed (started by %1 at %2). Try again when that run has finished.', Comment = '%1 = user, %2 = date and time';
        PostingFailedMsg: Label 'The returns journal for marketplace %1 could not be built or posted: %2', Comment = '%1 = marketplace id, %2 = error';
        LockKeyTxt: Label 'RETURNS', Locked = true;

    procedure ReadInbox()
    var
        Inbox: Record "Amazon Report Inbox";
        EntryNos: List of [BigInteger];
        EntryNo: BigInteger;
    begin
        Inbox.SetCurrentKey("Report Type", Processed, Attempts, "Entry No.");
        Inbox.SetRange("Report Type", Inbox."Report Type"::Returns);
        Inbox.SetRange(Processed, false);
        Inbox.SetFilter(Attempts, '<%1', MaxInboxAttempts());
        if Inbox.FindSet() then
            repeat
                EntryNos.Add(Inbox."Entry No.");
            until Inbox.Next() = 0;

        foreach EntryNo in EntryNos do
            ReadInboxEntry(EntryNo);
    end;

    procedure CheckReceivedReturns()
    var
        InventoryEvent: Record "Amazon Inventory Event";
        EntryNos: List of [BigInteger];
        EntryNo: BigInteger;
    begin
        InventoryEvent.SetCurrentKey(Status, "Marketplace Id", "Return Date");
        InventoryEvent.SetRange(Status, InventoryEvent.Status::Received);
        if InventoryEvent.FindSet() then
            repeat
                EntryNos.Add(InventoryEvent."Entry No.");
            until InventoryEvent.Next() = 0;

        foreach EntryNo in EntryNos do
            CheckReturn(EntryNo);
    end;

    procedure PostReadyReturns()
    var
        Setup: Record "Amazon Marketplace Setup";
    begin
        Setup.SetFilter("Process Returns From", '<>%1', 0D);
        if Setup.FindSet() then
            repeat
                PostMarketplace(Setup);
            until Setup.Next() = 0;
    end;

    local procedure ReadInboxEntry(EntryNo: BigInteger)
    var
        Inbox: Record "Amazon Report Inbox";
        Succeeded: Boolean;
        ErrorText: Text;
    begin
        if not Inbox.Get(EntryNo) then
            exit;
        Commit();
        ClearLastError();
        Succeeded := Codeunit.Run(Codeunit::"Amazon Return Import", Inbox);
        ErrorText := GetLastErrorText();

        Inbox.Get(EntryNo);
        Inbox.Attempts += 1;
        if Succeeded then begin
            Inbox.Processed := true;
            Inbox."Processed At" := CurrentDateTime();
            Inbox."Error Message" := '';
        end else
            Inbox."Error Message" := CopyStr(ErrorText, 1, MaxStrLen(Inbox."Error Message"));
        Inbox.Modify();
        Commit();
    end;

    local procedure CheckReturn(EntryNo: BigInteger)
    var
        InventoryEvent: Record "Amazon Inventory Event";
        Succeeded: Boolean;
        ErrorText: Text;
    begin
        if not InventoryEvent.Get(EntryNo) then
            exit;
        InventoryEvent.Attempts += 1;
        InventoryEvent.Modify();
        Commit();

        ClearLastError();
        Succeeded := Codeunit.Run(Codeunit::"Amazon Return Processing", InventoryEvent);
        ErrorText := GetLastErrorText();

        if not Succeeded then begin
            InventoryEvent.Get(EntryNo);
            InventoryEvent.Status := InventoryEvent.Status::Error;
            InventoryEvent."Status Message" := CopyStr(ErrorText, 1, MaxStrLen(InventoryEvent."Status Message"));
            InventoryEvent.Modify();
        end;
        Commit();
    end;

    local procedure PostMarketplace(Setup: Record "Amazon Marketplace Setup")
    var
        Succeeded: Boolean;
        ErrorText: Text;
    begin
        Commit();
        ClearLastError();
        Succeeded := Codeunit.Run(Codeunit::"Amazon Return Posting", Setup);
        ErrorText := GetLastErrorText();
        if not Succeeded then
            MarkPostingFailed(Setup."Marketplace Id", ErrorText);
        Commit();
    end;

    // Nothing was kept from the failed run, so the ready returns are put in Error with the reason.
    // Reprocess sends them back through once the cause is fixed.
    local procedure MarkPostingFailed(MarketplaceId: Code[20]; ErrorText: Text)
    var
        InventoryEvent: Record "Amazon Inventory Event";
        EventToMark: Record "Amazon Inventory Event";
        Problem: Text;
    begin
        Problem := StrSubstNo(PostingFailedMsg, MarketplaceId, ErrorText);
        InventoryEvent.SetCurrentKey(Status, "Marketplace Id", "Return Date");
        InventoryEvent.SetRange(Status, InventoryEvent.Status::Ready);
        InventoryEvent.SetRange("Marketplace Id", MarketplaceId);
        if InventoryEvent.FindSet() then
            repeat
                // Changed through a second record so the loop's status filter is not disturbed.
                EventToMark.Get(InventoryEvent."Entry No.");
                EventToMark.Status := EventToMark.Status::Error;
                EventToMark."Status Message" := CopyStr(Problem, 1, MaxStrLen(EventToMark."Status Message"));
                EventToMark.Modify();
            until InventoryEvent.Next() = 0;
    end;

    // Takes the returns row of the job lock, or returns false if another run already holds it.
    local procedure TryTakeLock(): Boolean
    var
        JobLock: Record "Amazon Order Job Lock";
    begin
        JobLock.LockTable();
        if not JobLock.Get(LockKeyTxt) then begin
            JobLock.Init();
            JobLock."Primary Key" := LockKeyTxt;
            if not JobLock.Insert() then
                JobLock.Get(LockKeyTxt);
        end;

        if IsHeldByAnotherRun(JobLock) then begin
            Commit();
            if GuiAllowed() then
                Message(AlreadyRunningMsg, JobLock."Started By", JobLock."Started At");
            exit(false);
        end;

        JobLock."Server Instance Id" := ServiceInstanceId();
        JobLock."Session Id" := SessionId();
        JobLock."Started At" := CurrentDateTime();
        JobLock."Started By" := CopyStr(UserId(), 1, MaxStrLen(JobLock."Started By"));
        JobLock.Modify();
        Commit();
        exit(true);
    end;

    local procedure IsHeldByAnotherRun(JobLock: Record "Amazon Order Job Lock"): Boolean
    var
        ActiveSession: Record "Active Session";
    begin
        if JobLock."Session Id" = 0 then
            exit(false);
        if (JobLock."Server Instance Id" = ServiceInstanceId()) and (JobLock."Session Id" = SessionId()) then
            exit(false);
        if CurrentDateTime() - JobLock."Started At" > MaxRunDuration() then
            exit(false);
        exit(ActiveSession.Get(JobLock."Server Instance Id", JobLock."Session Id"));
    end;

    local procedure ReleaseLock()
    var
        JobLock: Record "Amazon Order Job Lock";
    begin
        if not JobLock.Get(LockKeyTxt) then
            exit;
        if (JobLock."Server Instance Id" <> ServiceInstanceId()) or (JobLock."Session Id" <> SessionId()) then
            exit;
        JobLock."Server Instance Id" := 0;
        JobLock."Session Id" := 0;
        JobLock.Modify();
        Commit();
    end;

    local procedure MaxInboxAttempts(): Integer
    begin
        exit(3);
    end;

    local procedure MaxRunDuration(): Duration
    begin
        exit(60 * 60 * 1000); // one hour
    end;
}

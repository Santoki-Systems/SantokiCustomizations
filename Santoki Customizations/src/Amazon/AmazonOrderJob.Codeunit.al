// The scheduled job: read new deliveries, check received orders, then create sales orders.
//
// Run it from the job queue every few minutes, or from the Amazon Orders page. Each delivery and
// each order is handled in its own transaction, so one bad order is marked Error and the rest
// carry on.
//
// Only one run at a time: a run takes the Amazon Order Job Lock first, and a second run that
// starts while it holds it stops without touching anything.
codeunit 50208 "Amazon Order Job"
{
    trigger OnRun()
    begin
        if not TryTakeLock() then
            exit;

        ReadInbox();
        ProcessOrders(Enum::"Amazon Staging Status"::Received);
        ProcessOrders(Enum::"Amazon Staging Status"::Ready);

        ReleaseLock();
    end;

    var
        AlreadyRunningMsg: Label 'Amazon orders are already being processed (started by %1 at %2). Try again when that run has finished.', Comment = '%1 = user, %2 = date and time';

    procedure ReadInbox()
    var
        Inbox: Record "Amazon Order Inbox";
        EntryNos: List of [BigInteger];
        EntryNo: BigInteger;
    begin
        Inbox.SetCurrentKey(Processed, Attempts, "Entry No.");
        Inbox.SetRange(Processed, false);
        Inbox.SetFilter(Attempts, '<%1', MaxInboxAttempts());
        if Inbox.FindSet() then
            repeat
                EntryNos.Add(Inbox."Entry No.");
            until Inbox.Next() = 0;

        foreach EntryNo in EntryNos do
            ReadInboxEntry(EntryNo);
    end;

    procedure ProcessOrders(StatusToProcess: Enum "Amazon Staging Status")
    var
        StagedOrder: Record "Amazon Staged Order";
        OrderIds: List of [Code[30]];
        OrderId: Code[30];
    begin
        StagedOrder.SetCurrentKey(Status, "Purchase Date");
        StagedOrder.SetRange(Status, StatusToProcess);
        if StagedOrder.FindSet() then
            repeat
                OrderIds.Add(StagedOrder."Amazon Order Id");
            until StagedOrder.Next() = 0;

        foreach OrderId in OrderIds do
            ProcessOrder(OrderId);
    end;

    local procedure ReadInboxEntry(EntryNo: BigInteger)
    var
        Inbox: Record "Amazon Order Inbox";
        Succeeded: Boolean;
        ErrorText: Text;
    begin
        if not Inbox.Get(EntryNo) then
            exit;
        Commit();
        ClearLastError();
        Succeeded := Codeunit.Run(Codeunit::"Amazon Order Import", Inbox);
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

    local procedure ProcessOrder(OrderId: Code[30])
    var
        StagedOrder: Record "Amazon Staged Order";
        Succeeded: Boolean;
        ErrorText: Text;
    begin
        if not StagedOrder.Get(OrderId) then
            exit;

        // Mark the order before creating anything and commit that, so an interrupted run leaves
        // an In Progress order to check, rather than one that is quietly created a second time.
        if StagedOrder.Status = StagedOrder.Status::Ready then
            StagedOrder.Status := StagedOrder.Status::"In Progress";
        StagedOrder.Attempts += 1;
        StagedOrder."Last Attempt At" := CurrentDateTime();
        StagedOrder.Modify();
        Commit();

        ClearLastError();
        Succeeded := Codeunit.Run(Codeunit::"Amazon Order Processing", StagedOrder);
        ErrorText := GetLastErrorText();

        if not Succeeded then begin
            StagedOrder.Get(OrderId);
            StagedOrder.Status := StagedOrder.Status::Error;
            StagedOrder."Status Message" := CopyStr(ErrorText, 1, MaxStrLen(StagedOrder."Status Message"));
            StagedOrder.Modify();
        end;
        Commit();
    end;

    // Takes the job lock, or returns false if another run already holds it.
    local procedure TryTakeLock(): Boolean
    var
        JobLock: Record "Amazon Order Job Lock";
    begin
        JobLock.LockTable();
        if not JobLock.Get() then begin
            JobLock.Init();
            if not JobLock.Insert() then
                JobLock.Get();
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

        // A session runs one thing at a time, so a lock this session already holds is left over
        // from an earlier run that stopped on an error.
        if (JobLock."Server Instance Id" = ServiceInstanceId()) and (JobLock."Session Id" = SessionId()) then
            exit(false);

        // A run that has gone on far longer than any real one is treated as abandoned.
        if CurrentDateTime() - JobLock."Started At" > MaxRunDuration() then
            exit(false);

        exit(ActiveSession.Get(JobLock."Server Instance Id", JobLock."Session Id"));
    end;

    local procedure ReleaseLock()
    var
        JobLock: Record "Amazon Order Job Lock";
    begin
        if not JobLock.Get() then
            exit;
        // Only release a lock this run still holds; it may have been taken over as abandoned.
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
        exit(60 * 60 * 1000); // one hour; a normal run takes seconds to a few minutes
    end;
}

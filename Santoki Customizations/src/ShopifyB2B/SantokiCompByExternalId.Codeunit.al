// Shopify B2B company mapping by External Id, added for the B2B site launch in November 2026.
//
// Each Shopify company on the SANTOKIB2B shop carries the Business Central customer no. in its
// External Id. The standard "By Email/Phone" mapping ignores it and matches on the main contact's
// email, which fails where several customers share one email. This mapping uses the External Id.
//
// How the connector uses it: on an order for a company it hasn't linked yet, the connector imports
// the company from Shopify, which fills External Id, then calls FindMapping below. Once a company is
// linked to a customer, later orders reuse that link and this code isn't called again.
//
// Rules:
// - External Id filled in: link to the customer with that number. If none exists, leave the company
//   unlinked, so the order waits on the Shopify Orders page. Never fall back to email.
// - External Id blank: use the standard email/phone matching.
// Turn off Auto Create Unknown Companies on the shop, or an unmatched company gets a new customer.
codeunit 50201 "Santoki Comp. By External Id" implements "Shpfy ICompany Mapping", "Shpfy IFind Company Mapping"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure DoMapping(CompanyId: BigInteger; ShopCode: Code[20]; TemplateCode: Code[20]; AllowCreate: Boolean): Code[20]
    var
        StandardMapping: Interface "Shpfy ICompany Mapping";
    begin
        // The standard routine returns the customer of a company that's already linked. Otherwise it
        // imports the company from Shopify, and the import calls FindMapping below to do the matching.
        StandardMapping := Enum::"Shpfy Company Mapping"::"By Email/Phone";
        exit(StandardMapping.DoMapping(CompanyId, ShopCode, TemplateCode, AllowCreate));
    end;

    procedure FindMapping(var ShopifyCompany: Record "Shpfy Company"; var TempShopifyCustomer: Record "Shpfy Customer" temporary): Boolean
    var
        Customer: Record Customer;
        StandardMapping: Interface "Shpfy ICompany Mapping";
        ExternalId: Text;
    begin
        if not IsNullGuid(ShopifyCompany."Customer SystemId") then
            if Customer.GetBySystemId(ShopifyCompany."Customer SystemId") then
                exit(true)
            else begin
                Clear(ShopifyCompany."Customer SystemId");
                ShopifyCompany.Modify(true);
            end;

        ExternalId := DelChr(ShopifyCompany."External Id", '<>', ' ');
        if ExternalId = '' then begin
            StandardMapping := Enum::"Shpfy Company Mapping"::"By Email/Phone";
            exit((StandardMapping as "Shpfy IFind Company Mapping").FindMapping(ShopifyCompany, TempShopifyCustomer));
        end;

        if StrLen(ExternalId) > MaxStrLen(Customer."No.") then
            exit(false);
        if not Customer.Get(CopyStr(UpperCase(ExternalId), 1, MaxStrLen(Customer."No."))) then
            exit(false);

        LinkCompanyToCustomer(ShopifyCompany, TempShopifyCustomer, Customer);
        exit(true);
    end;

    // Same steps as the standard mappings: link the company and record its main contact. If the
    // contact is already known, for example because it's shared with another company, it's left as is.
    local procedure LinkCompanyToCustomer(var ShopifyCompany: Record "Shpfy Company"; var TempShopifyCustomer: Record "Shpfy Customer" temporary; Customer: Record Customer)
    var
        ShopifyCustomer: Record "Shpfy Customer";
    begin
        ShopifyCompany."Customer SystemId" := Customer.SystemId;

        if TempShopifyCustomer.Id <> 0 then begin
            if not ShopifyCustomer.Get(TempShopifyCustomer.Id) then begin
                ShopifyCustomer.TransferFields(TempShopifyCustomer);
                ShopifyCustomer."Customer SystemId" := Customer.SystemId;
                ShopifyCustomer.Insert(true);
            end;
            ShopifyCompany."Main Contact Customer Id" := ShopifyCustomer.Id;
        end;

        ShopifyCompany.Modify(true);
    end;
}

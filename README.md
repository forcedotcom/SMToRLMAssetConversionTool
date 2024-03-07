# SmToRlmAssetConversionTool

This project is a reference implementation to convert Assets with a Subscription Management (SM) data-shape to conform to the Revenue Lifecycle Management (RLM) data-shape so that Assets can continue to be amended, renewed, and/or cancelled in RLM.

## Requirements

### Salesforce Org Licenses and Permissions

- Active Subscription Management license
- Active Revenue Lifecycle Management license
- CalmSObjectAccess organization permission **enabled**

### User Permissions and Entity Access

- “Access Lifecycle-Managed Assets” user permission **enabled**
- **Read** access for the following entities and fields:
    - Asset Action
        - AssetId
        - CategoryEnum
    - Order Item
        - UnitPrice
        - NetUnitPrice
        - ListPrice
        - TotalPrice
        - TotalLineAmount
        - ObligatedAmount
        - PeriodBoundary
        - PeriodBoundaryDay
        - PeriodBoundaryStartMonth
        - PricingTermCount
        - PricebookEntryId
        - ProductSellingModelId
        - ProrationPolicyId
        - TaxTreatmentId
    - Order Item Relationship
        - AssociatedOrderItemPricing
        - AssociatedQuantScaleMethod
    - Product Related Component
        - ParentProductId
        - ChildProductId


- **Update** access for the following entities and fields:
    - Asset Action Source
        - UnitPrice
        - NetUnitPrice
        - ListPrice
        - TotalPrice
        - TotalLineAmount
        - ObligatedAmount
        - PeriodBoundary
        - PeriodBoundaryDay
        - PeriodBoundaryStartMonth
        - PricingTermCount
        - PricebookEntryId
        - ProductSellingModelId
        - ProrationPolicyId
        - TaxTreatmentId
    - Asset Relationship
        - RelatedAssetPricing
        - RelatedAssetQtyScaleMethod
        - ProductRelatedComponentId

### Limits
- 0 < `assetIds.size()` <= 200
- If the Id of an Asset belonging to a collection of bundled Assets is included in the input to `assetIds`, then the Ids of ALL Assets in the associated bundle must be included in `assetIds`.

## Notes
- Users can change or disable the validations associated with the above access checks and limits by making changes to their functions within the `SmToRlmAssetConverter` and `SmToRlmAssetConverterUtil` classes. Without these validations in place, Salesforce platform and Apex execution limits are still enforced and users must ensure their use of the SmToRlmAssetConversionTool is in compliance.
- While the project performs some validations of the input data before converting the Assets, these validations aren't exhaustive, and they offer no guarantee of success. Additionally, as with any data migration, there’s a potential for data corruption resulting from the conversion, and validations offer no guarantee against this. We strongly advise users to extensively test their use of the SmToRlmAssetConversionTool in sandbox environments and ensure the operation executes as expected before using it live in production. This project is not a replacement for a thorough testing process that the users should pursue.

## Salesforce DX Project: Next Steps

Now that you’ve created a Salesforce DX project, what’s next? Here are some documentation resources to get you started.

### How do you plan to deploy your changes?

Do you want to deploy a set of changes, or create a self-contained application? Choose a [development model](https://developer.salesforce.com/tools/vscode/en/user-guide/development-models).

### Configure Your Salesforce DX Project

The `sfdx-project.json` file contains useful configuration information for your project. See [Salesforce DX Project Configuration](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_config.htm) in the _Salesforce DX Developer Guide_ for details about this file.

### Read All About It

- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)

## How to invoke this tool in an Execute Anonymous window
- Open Execute anonymous window on developer console.
- Replace `<List of Asset Ids>` with a List of Asset Ids you want to convert and call the convert function. For example:
```
SmToRlmAssetConverter converter = new SmToRlmAssetConverter();
converter.assetIds = <List of Asset Ids>;
converter.convert();
```
- Open debug logs to verify result of execution.
- On success, check the fields on Asset Action Sources and Asset Relationships of converted Assets to verify fields are correctly populated.
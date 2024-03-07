public with sharing class SmToRlmAssetConverterUtil {

    private static final List<String> ASSET_ACTION_FIELDS = new List<String>{'AssetId', 'CategoryEnum'};
    private static final List<String> AAS_AND_OI_FIELDS = new List<String>{'UnitPrice', 'NetUnitPrice', 'ListPrice', 'TotalPrice', 'TotalLineAmount', 'ObligatedAmount', 'PeriodBoundary', 'PeriodBoundaryDay', 'PeriodBoundaryStartMonth', 'PricingTermCount', 'PricebookEntryId', 'ProductSellingModelId', 'ProrationPolicyId', 'TaxTreatmentId'};
    private static final List<String> ASSET_RELATIONSHIP_FIELDS = new List<String>{'RelatedAssetPricing', 'RelatedAssetQtyScaleMethod', 'ProductRelatedComponentId'};
    private static final List<String> ORDER_ITEM_RELATIONSHIP_FIELDS = new List<String>{'AssociatedOrderItemPricing', 'AssociatedQuantScaleMethod'};
    private static final List<String> PRODUCT_RELATED_COMPONENT_FIELDS = new List<String>{'ParentProductId', 'ChildProductId'};

    public static Map<Id, AssetRelationship> queryAssetRelationshipMap(List<Id> assetIds) {
        Map<Id, AssetRelationship> assetRelationshipIdToAssetRelationships;
        try {
            validateUpdateAccessOnAssetRelationship();
            // Query Asset Relationship records from the database and convert into a map
            assetRelationshipIdToAssetRelationships = new Map<Id, AssetRelationship>([SELECT Id, AssetId, Asset.Product2Id, RelatedAssetId, RelatedAsset.Product2Id, RelatedAssetPricing, RelatedAssetQtyScaleMethod, ProductRelatedComponentId FROM AssetRelationship WHERE AssetId IN :assetIds OR RelatedAssetId IN :assetIds]);
        } catch(Exception e) {
            System.debug('An error occurred while querying Asset Relationship records: ' +  e.getMessage());
        }
        return assetRelationshipIdToAssetRelationships;
    }

    public static Map<Id, AssetActionSource> queryAssetActionSourcesMap(List<Id> assetIds) {
        Map<Id, AssetActionSource> assetActionSourceIdToAssetActionSources;
        try {
            validateReadAccessOnAssetAction();
            validateUpdateAccessOnAssetActionSource();
            // Query Asset Action Source records from the database and convert into a map
            assetActionSourceIdToAssetActionSources = new Map<Id, AssetActionSource>([SELECT Id, AssetAction.AssetId, AssetAction.CategoryEnum, ReferenceEntityItemId, UnitPrice, ListPrice, NetUnitPrice, TotalPrice, TotalLineAmount, ObligatedAmount, PricingTermCount, PeriodBoundary, PeriodBoundaryDay, PeriodBoundaryStartMonth, TaxTreatmentId, PricebookEntryId, ProductSellingModelId, ProrationPolicyId FROM AssetActionSource WHERE AssetAction.AssetId IN :assetIds AND ReferenceEntityItem.Type = 'OrderItem']);
        } catch(Exception e) {
            System.debug('An error occurred while querying Asset Action Source records: ' +  e.getMessage());
        }
        return assetActionSourceIdToAssetActionSources;
    }

    public static Map<Id, OrderItem> queryOrderItemsMap(List<Id> orderItemIds) {
        Map<Id, OrderItem> orderItemIdToOrderItems;
        try {
            validateReadAccessOnOrderItem();
            // Query Order Item records from the database and convert into a map
            orderItemIdToOrderItems = new Map<Id, OrderItem>([SELECT Id, Quantity, UnitPrice, ListPrice, NetUnitPrice, TotalPrice, TotalLineAmount, ObligatedAmount, PricingTermCount, PeriodBoundary, PeriodBoundaryDay, PeriodBoundaryStartMonth, TaxTreatmentId, PricebookEntryId, ProductSellingModelId, ProrationPolicyId FROM OrderItem WHERE Id IN :orderItemIds]);
        } catch(Exception e) {
            System.debug('An error occurred while querying Order Item records: ' +  e.getMessage());
        }
        return orderItemIdToOrderItems;
    }

    public static List<OrderItemRelationship> queryOrderItemRelationships(List<Id> orderItemIds) {
        List<OrderItemRelationship> orderItemRelationships;
        try {
            validateReadAccessOnOrderItemRelationship();
            // Query Order Item Relationship records from the database 
            orderItemRelationships = new List<OrderItemRelationship>([SELECT Id, MainOrderItemId, AssociatedOrderItemId, AssociatedOrderItemPricing, AssociatedQuantScaleMethod FROM OrderItemRelationship WHERE MainOrderItemId IN :orderItemIds]);
        } catch(Exception e) {
            System.debug('An error occurred while querying Order Item Relationship records: ' +  e.getMessage());
        }
        return orderItemRelationships;
    }

    public static List<ProductRelatedComponent> queryProductRelatedComponents(List<Id> parentProductIds, List<Id> childProductIds) {
        List<ProductRelatedComponent> productRelatedComponents;
        try {
            validateReadAccessOnProductRelatedComponent();
            // Query Product Related Component records from the database 
            productRelatedComponents = new List<ProductRelatedComponent>([SELECT Id, ParentProductId, ChildProductId FROM ProductRelatedComponent WHERE ParentProductId IN :parentProductIds AND ChildProductId IN :childProductIds]);
        } catch(Exception e) {
            System.debug('An error occurred while querying Product Related Component records: ' +  e.getMessage());
        }
        return productRelatedComponents;
    }

    public static void validateReadAccessOnAssetAction() {
        if (!hasReadAccessOnSObject(Schema.SObjectType.AssetAction, ASSET_ACTION_FIELDS)) {
            raiseReadAccessException('Asset Action');
        }
    }

    public static void validateReadAccessOnOrderItem() {
        if (!hasReadAccessOnSObject(Schema.SObjectType.OrderItem, AAS_AND_OI_FIELDS)) {
            raiseReadAccessException('Order Item');
        }
    }

    public static void validateReadAccessOnOrderItemRelationship() {
        if (!hasReadAccessOnSObject(Schema.SObjectType.OrderItemRelationship, ORDER_ITEM_RELATIONSHIP_FIELDS)) {
            raiseReadAccessException('Order Item Relationship');
        }
    }

    public static void validateReadAccessOnProductRelatedComponent() {
        if (!hasReadAccessOnSObject(Schema.SObjectType.ProductRelatedComponent, PRODUCT_RELATED_COMPONENT_FIELDS)) {
            raiseReadAccessException('Product Related Component');
        }
    }

    public static void validateUpdateAccessOnAssetActionSource() {
        if (!hasUpdateAccessOnSObject(Schema.SObjectType.AssetActionSource, AAS_AND_OI_FIELDS)) {
            raiseUpdateAccessException('Asset Action Source');
        }
    }

    public static void validateUpdateAccessOnAssetRelationship() {
        if (!hasUpdateAccessOnSObject(Schema.SObjectType.AssetRelationship, ASSET_RELATIONSHIP_FIELDS)) {
            raiseUpdateAccessException('Asset Relationship');
        }
    }

    private static Boolean hasReadAccessOnSObject(Schema.DescribeSObjectResult descrSObjectRes, List<String> sObjectFields) {
        Boolean hasAccess = descrSObjectRes.isAccessible();
        if (hasAccess) {
            Map<String, Schema.SObjectField> fieldMap = descrSObjectRes.fields.getMap();
            for (String field : sObjectFields) {
                hasAccess &= fieldMap.containsKey(field) && fieldMap.get(field).getDescribe().isAccessible();
            }
        }
        return hasAccess;
    }

    private static Boolean hasUpdateAccessOnSObject(Schema.DescribeSObjectResult descrSObjectRes, List<String> sObjectFields) {
        Boolean hasAccess = descrSObjectRes.isAccessible();
        if (hasAccess) {
            Map<String, Schema.SObjectField> fieldMap = descrSObjectRes.fields.getMap();
            for (String field : sObjectFields) {
                hasAccess &= fieldMap.containsKey(field) && fieldMap.get(field).getDescribe().isUpdateable();
            }
        }
        return hasAccess;
    }

    private static void raiseReadAccessException(String sObjectName) {
        throw new SmToRlmAssetConversionException('Cannot read the required fields on ' + sObjectName + ' SObjects. Check your permissions.');
    }

    private static void raiseUpdateAccessException(String sObjectName) {
        throw new SmToRlmAssetConversionException('Cannot update the required fields on ' + sObjectName + ' SObjects. Check your permissions.');
    }
}
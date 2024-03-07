public with sharing class SmToRlmAssetConverter {
    // Property to store a list of Asset Ids to convert
    public List<Id> assetIds { get; set; }

    // Private variables for necessary data structures
    private Map<Id, AssetActionSource> assetActionSourceIdToAssetActionSources;
    private Map<Id, OrderItem> orderItemIdToOrderItems;
    private Map<Id, AssetActionSource> assetIdToInitialSaleAssetActionSources;
    private Map<Id, AssetRelationship> assetRelationshipIdToAssetRelationships;
    private Map<Id, OrderItemRelationship> orderItemIdToOrderItemRelationships;
    private Map<Id, Id> assetRelationshipIdToProductRelatedComponentIds;
    private List<Id> parentProductIds;
    private List<Id> childProductIds;

    public SmToRlmAssetConverter() {
        assetIds = null;
        assetActionSourceIdToAssetActionSources = new Map<Id, AssetActionSource>();
        orderItemIdToOrderItems = new Map<Id, OrderItem>();
        assetIdToInitialSaleAssetActionSources = new Map<Id, AssetActionSource>();
        assetRelationshipIdToAssetRelationships = new Map<Id, AssetRelationship>();
        orderItemIdToOrderItemRelationships = new Map<Id, OrderItemRelationship>();
        assetRelationshipIdToProductRelatedComponentIds = new Map<Id, Id>();
        parentProductIds = new List<Id>();
        childProductIds = new List<Id>();
    }

    public void convert() {
        // Validate number of Asset Ids
        validateAssetIds();

        // Validate the user has the required SObject access permissions
        validateSObjectAccess();

        // Query related entities and build maps
        queryEntities();

        // Update RLM fields on Asset Action Sources
        updateAssetActionSourceFields();

        // Update RLM fields on Asset Relationships
        updateAssetRelationshipFields();
    }

    private void validateSObjectAccess() {
        // User requires read access on: Asset Action, Order Item, Order Item Relationship, and Product Related Component
        SmToRlmAssetConverterUtil.validateReadAccessOnAssetAction();
        SmToRlmAssetConverterUtil.validateReadAccessOnOrderItem();
        SmToRlmAssetConverterUtil.validateReadAccessOnOrderItemRelationship();
        SmToRlmAssetConverterUtil.validateReadAccessOnProductRelatedComponent();

        // User requires Update access on: Asset Action Source and Asset Relationship
        SmToRlmAssetConverterUtil.validateUpdateAccessOnAssetActionSource();
        SmToRlmAssetConverterUtil.validateUpdateAccessOnAssetRelationship();
    }

    private void validateAssetIds() {
        if (assetIds == null || assetIds.size() == 0) {
            throw new SmToRlmAssetConversionException('No Asset Ids were provided. Please add at least one Asset Id to assetIds.');
        } else if (assetIds.size() > 200) {
            throw new SmToRlmAssetConversionException('Too many Asset Ids were provided. Number of Asset Ids in assetIds should be less than or equal to 200.');
        }

        // If any bundled Asset Ids are included in the input, then validate that all asset Ids for that bundle are included
        validateBundledAssetIds();
    }

    private void validateBundledAssetIds() {
        Set<Id> assetIdSet = new Set<Id>(assetIds);
        assetRelationshipIdToAssetRelationships = SmToRlmAssetConverterUtil.queryAssetRelationshipMap(assetIds);
        if (assetRelationshipIdToAssetRelationships != null) {
            for (Id assetRelationshipId : assetRelationshipIdToAssetRelationships.keySet()) {
                AssetRelationship assetRelationship = assetRelationshipIdToAssetRelationships.get(assetRelationshipId);
                Id assetId = assetRelationship.AssetId;
                Id relatedAssetId = assetRelationship.RelatedAssetId;
                parentProductIds.add(assetRelationship.Asset.Product2Id);
                childProductIds.add(assetRelationship.RelatedAsset.Product2Id);
                // Validate that Asset and RelatedAsset Ids are included in assetIds
                if (!assetIdSet.contains(assetId)) {
                    throw new SmToRlmAssetConversionException('AssetId (' + assetId + ') from AssetRelationship ' + assetRelationship.Id + ' is missing. Include this Id with assetIds and run the tool again.');
                }
                if (!assetIdSet.contains(relatedAssetId)) {
                    throw new SmToRlmAssetConversionException('RelatedAssetId (' + relatedAssetId + ') from AssetRelationship ' + assetRelationship.Id + ' is missing. Include this Id with assetIds and run the tool again.');
                }
            }
        }
    }

    private void queryEntities() {
        // Create map of Asset Action Source Id to Asset Action Source
        assetActionSourceIdToAssetActionSources = SmToRlmAssetConverterUtil.queryAssetActionSourcesMap(assetIds);

        List<Id> orderItemIds = new List<Id>();
        List<Id> initialSaleOrderItemIds = new List<Id>();

        // Create map of Asset Id to Asset Action Source Ids
        for (String aasId : assetActionSourceIdToAssetActionSources.keySet()) {
            AssetActionSource aas = assetActionSourceIdToAssetActionSources.get(aasId);

            // Add entry to assetIdToInitialSaleAssetActionSources if parent Asset Action category is "Initial Sale"
            if (aas.AssetAction.CategoryEnum == 'Initial Sale') {
                assetIdToInitialSaleAssetActionSources.put(aas.AssetAction.AssetId, aas);
                Id initialSaleOrderItemId = aas.ReferenceEntityItemId;
                initialSaleOrderItemIds.add(initialSaleOrderItemId);
            }

            orderItemIds.add(aas.ReferenceEntityItemId);
        }

        // Create map of Order Item Id to Order Item
        orderItemIdToOrderItems = SmToRlmAssetConverterUtil.queryOrderItemsMap(orderItemIds);

        // Get Order Item Relationships from Initial Sale Order Items and create map of Associated Order Item Id to Order Item Relationship
        List<OrderItemRelationship> orderItemRelationships = SmToRlmAssetConverterUtil.queryOrderItemRelationships(initialSaleOrderItemIds);
        for (OrderItemRelationship orderItemRelationship : orderItemRelationships) {
            Id associatedOrderItemId = orderItemRelationship.AssociatedOrderItemId;
            orderItemIdToOrderItemRelationships.put(associatedOrderItemId, orderItemRelationship);
        }

        // Create map of Asset Relationship Id to Product Related Component Ids
        if (parentProductIds.size() > 0 && childProductIds.size() > 0) {
            List<ProductRelatedComponent> productRelatedComponents = SmToRlmAssetConverterUtil.queryProductRelatedComponents(parentProductIds, childProductIds);
            if (productRelatedComponents != null && productRelatedComponents.size() > 0) {
                for (Id assetRelationshipId : assetRelationshipIdToAssetRelationships.keySet()) {
                    AssetRelationship assetRelationship = assetRelationshipIdToAssetRelationships.get(assetRelationshipId);
                    Id parentProductId = assetRelationship.Asset.Product2Id;
                    Id childProductId = assetRelationship.RelatedAsset.Product2Id;
                    for (ProductRelatedComponent productRelatedComponent : productRelatedComponents) {
                        if (productRelatedComponent.ParentProductId == parentProductId && productRelatedComponent.ChildProductId == childProductId) {
                            assetRelationshipIdToProductRelatedComponentIds.put(assetRelationship.Id, productRelatedComponent.Id);
                        }
                    }
                }
            }
        }
    }

    private void updateAssetActionSourceFields() {
        AssetActionSource[] assetActionSourcesToSave = new AssetActionSource[]{};

        for (Id assetActionSourceId : assetActionSourceIdToAssetActionSources.keySet()) {
            AssetActionSource assetActionSource = assetActionSourceIdToAssetActionSources.get(assetActionSourceId);
            Id orderItemId = assetActionSource.ReferenceEntityItemId;
            OrderItem orderItem = orderItemIdToOrderItems.get(orderItemId);

            // Map the fields
            assetActionSource.UnitPrice = orderItem.UnitPrice == null ? calculateUnitPrice(orderItem) : orderItem.UnitPrice;
            assetActionSource.NetUnitPrice = orderItem.NetUnitPrice;
            assetActionSource.ListPrice = orderItem.ListPrice;
            assetActionSource.TotalPrice = orderItem.TotalPrice;
            assetActionSource.TotalLineAmount = orderItem.TotalLineAmount == null ? calculateTotalLineAmount(orderItem) : orderItem.TotalLineAmount;
            assetActionSource.ObligatedAmount = orderItem.ObligatedAmount;
            assetActionSource.PricingTermCount = getPricingTermCount(orderItem);
            assetActionSource.PricebookEntryId = orderItem.PricebookEntryId;
            assetActionSource.ProductSellingModelId = orderItem.ProductSellingModelId;
            assetActionSource.ProrationPolicyId = orderItem.ProrationPolicyId;
            assetActionSource.TaxTreatmentId = orderItem.TaxTreatmentId;
            updatePeriodBoundaryFields(assetActionSource);

            assetActionSourcesToSave.add(assetActionSource);
        }

        update assetActionSourcesToSave;
    }

    private void updatePeriodBoundaryFields(AssetActionSource assetActionSource) {
        Id assetId = assetActionSource.AssetAction.AssetId;
        AssetActionSource initialSaleAssetActionSource = assetIdToInitialSaleAssetActionSources.get(assetId);
        Id initialSaleOrderItemId = initialSaleAssetActionSource.ReferenceEntityItemId;
        OrderItem initialSaleOrderItem = orderItemIdToOrderItems.get(initialSaleOrderItemId);
        assetActionSource.PeriodBoundary = initialSaleOrderItem.PeriodBoundary;
        assetActionSource.PeriodBoundaryDay = initialSaleOrderItem.PeriodBoundaryDay;
        assetActionSource.PeriodBoundaryStartMonth = initialSaleOrderItem.PeriodBoundaryStartMonth;
    }

    private Decimal calculateUnitPrice(OrderItem orderItem) {
        Decimal totalLineAmount = orderItem.TotalLineAmount;
        Decimal divisor = Decimal.valueOf((Double) orderItem.Quantity) + Decimal.valueOf(getPricingTermCount(orderItem));
        return totalLineAmount / divisor;
    }

    private Decimal calculateTotalLineAmount(OrderItem orderItem) {
        Decimal unitPrice = orderItem.UnitPrice;
        return unitPrice * Decimal.valueOf((Double) orderItem.Quantity) * Decimal.valueOf(getPricingTermCount(orderItem));
    }

    private Double getPricingTermCount(OrderItem orderItem) {
        return orderItem.PricingTermCount == null ? 1.0 : (Double)orderItem.PricingTermCount;
    }

    private void updateAssetRelationshipFields() {
        AssetRelationship[] assetRelationshipsToSave = new AssetRelationship[]{};

        for (Id assetRelationshipId : assetRelationshipIdToAssetRelationships.keySet()) {
            AssetRelationship assetRelationship = assetRelationshipIdToAssetRelationships.get(assetRelationshipId);
            Id relatedAssetId = assetRelationship.RelatedAssetId;
            AssetActionSource assetActionSource = assetIdToInitialSaleAssetActionSources.get(relatedAssetId);
            Id associatedOrderItemId = assetActionSource.ReferenceEntityItemId;
            OrderItemRelationship orderItemRelationship = orderItemIdToOrderItemRelationships.get(associatedOrderItemId);

            assetRelationship.RelatedAssetPricing = orderItemRelationship.AssociatedOrderItemPricing;
            assetRelationship.RelatedAssetQtyScaleMethod = orderItemRelationship.AssociatedQuantScaleMethod;
            assetRelationship.ProductRelatedComponentId = assetRelationshipIdToProductRelatedComponentIds.get(assetRelationship.Id);

            assetRelationshipsToSave.add(assetRelationship);
        } 

        update assetRelationshipsToSave;
    }
}
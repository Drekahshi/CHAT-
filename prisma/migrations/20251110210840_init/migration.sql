-- CreateTable
CREATE TABLE "creators" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "address" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "collectors" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "address" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "assets" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "creatorId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "assetType" TEXT NOT NULL,
    "ipfsHash" TEXT NOT NULL,
    "metadataUri" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'submitted',
    "aiVerificationResult" JSONB,
    "hederaAttestationId" TEXT,
    "hederaConsensusTimestamp" DATETIME,
    "ethereumContractAddress" TEXT,
    "ethereumTokenId" BIGINT,
    "accessLevel" TEXT NOT NULL,
    "genderSpecificAccess" TEXT,
    "attributes" JSONB,
    "language" TEXT,
    "region" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "assets_creatorId_fkey" FOREIGN KEY ("creatorId") REFERENCES "creators" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "marketplace_listings" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "assetId" TEXT NOT NULL,
    "sellerId" TEXT NOT NULL,
    "individualPrice" DECIMAL,
    "commercialPrice" DECIMAL,
    "institutionalPrice" DECIMAL,
    "listingStatus" TEXT NOT NULL,
    "createdAt" DATETIME,
    "delistedAt" DATETIME,
    "soldAt" DATETIME,
    CONSTRAINT "marketplace_listings_assetId_fkey" FOREIGN KEY ("assetId") REFERENCES "assets" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "marketplace_listings_sellerId_fkey" FOREIGN KEY ("sellerId") REFERENCES "creators" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "sales_transactions" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "listingId" TEXT NOT NULL,
    "buyerId" TEXT NOT NULL,
    "sellerId" TEXT NOT NULL,
    "salePrice" DECIMAL,
    "platformFee" DECIMAL,
    "creatorRoyalty" DECIMAL,
    "sellerProceeds" DECIMAL,
    "ethereumTxHash" TEXT,
    "ethereumBlockNumber" BIGINT,
    "hederaAttestationId" TEXT,
    "saleTimestamp" DATETIME,
    CONSTRAINT "sales_transactions_listingId_fkey" FOREIGN KEY ("listingId") REFERENCES "marketplace_listings" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "sales_transactions_buyerId_fkey" FOREIGN KEY ("buyerId") REFERENCES "collectors" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "sales_transactions_sellerId_fkey" FOREIGN KEY ("sellerId") REFERENCES "creators" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "conservation_fund_locks" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "assetId" TEXT NOT NULL,
    "saleId" TEXT NOT NULL,
    "lockedAmount" DECIMAL,
    "lockTimestamp" DATETIME NOT NULL,
    "unlockTimestamp" DATETIME NOT NULL,
    "apyPercentage" DECIMAL DEFAULT 12.00,
    "accruedYield" DECIMAL DEFAULT 0,
    "status" TEXT NOT NULL,
    CONSTRAINT "conservation_fund_locks_assetId_fkey" FOREIGN KEY ("assetId") REFERENCES "assets" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "conservation_fund_locks_saleId_fkey" FOREIGN KEY ("saleId") REFERENCES "sales_transactions" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "validators" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "validatorAddress" TEXT NOT NULL,
    "validatorType" TEXT NOT NULL,
    "stakedAmount" DECIMAL NOT NULL,
    "slashedAmount" DECIMAL DEFAULT 0,
    "approvalsCount" BIGINT DEFAULT 0,
    "rejectionsCount" BIGINT DEFAULT 0,
    "slashIncidents" BIGINT DEFAULT 0,
    "active" BOOLEAN DEFAULT true,
    "electedAt" DATETIME,
    "electionExpiresAt" DATETIME
);

-- CreateIndex
CREATE UNIQUE INDEX "creators_address_key" ON "creators"("address");

-- CreateIndex
CREATE UNIQUE INDEX "collectors_address_key" ON "collectors"("address");

-- CreateIndex
CREATE INDEX "assets_creatorId_idx" ON "assets"("creatorId");

-- CreateIndex
CREATE INDEX "assets_status_idx" ON "assets"("status");

-- CreateIndex
CREATE INDEX "assets_assetType_idx" ON "assets"("assetType");

-- CreateIndex
CREATE INDEX "marketplace_listings_assetId_idx" ON "marketplace_listings"("assetId");

-- CreateIndex
CREATE INDEX "marketplace_listings_sellerId_idx" ON "marketplace_listings"("sellerId");

-- CreateIndex
CREATE INDEX "marketplace_listings_listingStatus_idx" ON "marketplace_listings"("listingStatus");

-- CreateIndex
CREATE INDEX "sales_transactions_buyerId_idx" ON "sales_transactions"("buyerId");

-- CreateIndex
CREATE INDEX "sales_transactions_sellerId_idx" ON "sales_transactions"("sellerId");

-- CreateIndex
CREATE INDEX "sales_transactions_ethereumTxHash_idx" ON "sales_transactions"("ethereumTxHash");

-- CreateIndex
CREATE INDEX "conservation_fund_locks_assetId_idx" ON "conservation_fund_locks"("assetId");

-- CreateIndex
CREATE INDEX "conservation_fund_locks_unlockTimestamp_idx" ON "conservation_fund_locks"("unlockTimestamp");

-- CreateIndex
CREATE INDEX "validators_active_idx" ON "validators"("active");

-- CreateIndex
CREATE INDEX "validators_electionExpiresAt_idx" ON "validators"("electionExpiresAt");

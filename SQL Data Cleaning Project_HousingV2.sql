/*
Data Cleaning Project
Nashville Housing Data 
 */

 SELECT *
 FROM PortfolioProjects.dbo.NashvilleHousing

 ---------------------------------------------------------------------
 -- Standarized Date Format 

--Add a new column at the end of the table named SaleDateConverted
 ALTER TABLE NashvilleHousing     
 ADD SaleDateConverted date;

 UPDATE NashvilleHousing
 SET SaleDateConverted = CONVERT(Date, SaleDate)

 SELECT SaleDateConverted, CONVERT(Date, SaleDate)
 FROM PortfolioProjects.dbo.NashvilleHousing

 ---------------------------------------------------------------------
 -- Populate Property Address Data

 SELECT PropertyAddress
 FROM PortfolioProjects.dbo.NashvilleHousing
 WHERE PropertyAddress is null
/*There are 29 Property Addresses with no information*/

 SELECT [UniqueID ], ParcelID, PropertyAddress
 FROM PortfolioProjects.dbo.NashvilleHousing
 ORDER BY ParcelID
 /*Shows some ParcelID values are duplicated
 It will be interesting to check if the Null Addresses have information in one of the 
 ParcelID that are duplicated*/

 /*  Checking if table "a" will be populated correctly using the information from table "b"  */

 SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, 
        IIF(ISNULL(a.PropertyAddress,b.PropertyAddress)= '', 'No Address', 'Address exists') as AddressStatus
 FROM PortfolioProjects.dbo.NashvilleHousing a
 join PortfolioProjects.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null


-- Populating Null Property Address  
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
 FROM PortfolioProjects.dbo.NashvilleHousing a
 join PortfolioProjects.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

-- Check if it was correctly populated by running the previous query. 
-- It will be correct if there is no rows showing in the query.

 SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, 
        IIF(ISNULL(a.PropertyAddress,b.PropertyAddress)= '', 'No Address', 'Address exists') as AddressStatus
 FROM PortfolioProjects.dbo.NashvilleHousing a
 join PortfolioProjects.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

 ----------------------------------------------------------------------
-- Breaking out Address into Individual Columns (Address, City, State)

 SELECT PropertyAddress
 FROM PortfolioProjects.dbo.NashvilleHousing
 --WHERE PropertyAddress is null
 --ORDER BY ParcelID

 SELECT 
 SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) as Address,
 SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) as City
 FROM PortfolioProjects.dbo.NashvilleHousing

 /*CHARINDEX('string of characters', column name) ruturns in what position start the character
 if -1 then it shows the position before the char and +1 after the char*/

 --Execute first the ALTER and then the UPDATE

 ALTER TABLE NashvilleHousing     
 ADD PropertySplitAddress varchar(255);

 ALTER TABLE NashvilleHousing     
 ADD PropertySplitCity varchar(255);

 UPDATE NashvilleHousing
 SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) 

 UPDATE NashvilleHousing
 SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))

 SELECT PropertySplitAddress, PropertySplitCity 
 FROM PortfolioProjects.dbo.NashvilleHousing

 ---------------- Spliting Owner Address -----------------
 SELECT OwnerAddress
 FROM PortfolioProjects.dbo.NashvilleHousing


 -- Spliting Owner Address using PARSENAME(column name, 1) starts from the back and separates by '.'
  SELECT
 PARSENAME(REPLACE(OwnerAddress, ',', '.'),3) as Address,
 PARSENAME(REPLACE(OwnerAddress, ',', '.'),2) as City,
 PARSENAME(REPLACE(OwnerAddress, ',', '.'),1) as State
 FROM PortfolioProjects.dbo.NashvilleHousing

 /*Run all ALTERs before the UPDATEs: Columns needs to be created first to populate them after*/
 ALTER TABLE NashvilleHousing     
 ADD OwnerSplitAddress varchar(255);

 ALTER TABLE NashvilleHousing     
 ADD OwnerSplitCity varchar(255);

 ALTER TABLE NashvilleHousing     
 ADD OwnerSplitState varchar(255);

 UPDATE NashvilleHousing
 SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)
 
 UPDATE NashvilleHousing
 SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)
 
 UPDATE NashvilleHousing
 SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)

 SELECT OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
 FROM PortfolioProjects.dbo.NashvilleHousing



-----------------------------------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vacant" field

Select distinct(SoldAsVacant), count(SoldAsVacant) 
From PortfolioProjects.dbo.NashvilleHousing
Group by SoldAsVacant
Order by 2


SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From PortfolioProjects.dbo.NashvilleHousing


Update NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END


-------------------------------------------------------------------------
-- Remove Duplicates
/*It is not recommended to delete duplicates from your data. 
It will be better if a temp table is created where the duplicates are not included*/

SELECT *
FROM PortfolioProjects.dbo.NashvilleHousing

-- Using CTE to check for duplicates
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM PortfolioProjects.dbo.NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1 
ORDER BY PropertyAddress
/*There are 104 duplicates*/

-- Using CTE to delete duplicates
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM PortfolioProjects.dbo.NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1




--------------------------------------------------------------------------
-- Delete Unused Columns (PropertyAddress, OwnerAddress, SaleDate, and TaxDistrict)

SELECT *
FROM PortfolioProjects.dbo.NashvilleHousing

ALTER TABLE PortfolioProjects.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

-------------------------------------------------------------------------
-- Create View for later visualizations

CREATE VIEW CleanNashvilleHousing2 AS
SELECT *
FROM PortfolioProjects.dbo.NashvilleHousing

SELECT *
FROM CleanNashvilleHousing2


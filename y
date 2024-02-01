CREATE PROCEDURE [dbo].[uspCli_WithinRadius] 
@Radius INT, 
@RadiusUnit VARCHAR(10), 
@UserLatitude FLOAT, 
@UserLongitude FLOAT
AS
BEGIN
    DECLARE @UserLocation GEOGRAPHY
    DECLARE @SearchArea GEOGRAPHY
    DECLARE @ConversionRate FLOAT

    IF UPPER(@RadiusUnit) = 'MILES'
        SET @ConversionRate = 1
    ELSE
        SET @ConversionRate = 0.621371

    SET @UserLocation = GEOGRAPHY::Point(@UserLatitude, @UserLongitude, 4326)
    SET @SearchArea = @UserLocation.STBuffer(@Radius * 1609.344 * @ConversionRate)

    CREATE TABLE #AddressesNearUser (
        AddressID INT,
        Latitude FLOAT,
        Longitude FLOAT
    )

    INSERT INTO #AddressesNearUser (AddressID, Latitude, Longitude)
    SELECT AddressID, Latitude, Longitude 
    FROM dbo.ADDRESSES (NOLOCK) 
    WHERE 
        LATITUDE BETWEEN @UserLatitude - (@Radius / (69.0 * @ConversionRate)) AND @UserLatitude + (@Radius / (69.0 * @ConversionRate))
        AND LONGITUDE BETWEEN @UserLongitude - @Radius / ABS(COS(RADIANS(@UserLatitude)) * (69.0 * @ConversionRate)) AND @UserLongitude + @Radius / ABS(COS(RADIANS(@UserLatitude)) * (69.0 * @ConversionRate))

    CREATE NONCLUSTERED INDEX [NCI_tempAddresses_nearUser_lat_long]
    ON [dbo].[#AddressesNearUser] ([Latitude], [Longitude])
    INCLUDE ([AddressID])

    SELECT 
        cs.SiteID,
        GEOGRAPHY::STPointFromText(
            'POINT(' + CAST(a.Longitude AS VARCHAR(20)) + ' ' + CAST(a.Latitude AS VARCHAR(20)) + ')', 4326
        ).STDistance(@UserLocation) / (1609.344 * @ConversionRate) AS DistanceFromClinic,
        GEOGRAPHY::STPointFromText(
            'POINT(' + CAST(a.Longitude AS VARCHAR(20)) + ' ' + CAST(a.Latitude AS VARCHAR(20)) + ')', 4326
        ) AS ClinicLocation
    FROM 
        collectionsite cs WITH (NOLOCK)
        JOIN csaddresses csadd WITH (NOLOCK) ON cs.siteid = csadd.siteid AND csadd.addresstype = 'OFFC'
        JOIN #AddressesNearUser a WITH (NOLOCK) ON csadd.addressid = a.addressid
    WHERE 
        cs.ACTIVE = 1
        AND cs.siteid > 100
        AND a.LATITUDE IS NOT NULL
        AND GEOGRAPHY::STPointFromText('POINT(' + CAST(a.Longitude AS VARCHAR(20)) + ' ' + CAST(a.Latitude AS VARCHAR(20)) + ')', 4326).Filter(@SearchArea) = 1

    DROP TABLE #AddressesNearUser
END

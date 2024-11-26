use spotify_analysis;

# Setting up the write & read settings before contiuning

SET AUTOCOMMIT = OFF; # Our write transactions will not save automatically. So we will need to comit changes if needed

# Manual need to save each transaction; Similar to a save point in video games
COMMIT; 

DELETE FROM SPOTIFY_SONGS;
SELECT *
FROM SPOTIFY_SONGS;


# From my last save point, I'll rollback after accidently deleteing all the rows
ROLLBACK;



# Data cleaning

ALTER TABLE spotify_songs
RENAME COLUMN `artist(s)_name` to artist_names;

# Locating Duplicates

WITH duplicated_tracks as (
SELECT track_name, artist_names, released_year, streams, 
	ROW_NUMBER() OVER (PARTITION BY track_name, artist_names, released_year ORDER BY released_year DESC) as Duplicated_songs
FROM spotify_songs
ORDER BY Duplicated_songs DESC
)
SELECT * 
FROM duplicated_tracks
WHERE Duplicated_songs > 1;

# Checking for EACH Duplicate
WITH duplicated_tracks as (
SELECT track_name, artist_names, released_year, streams, 
	ROW_NUMBER() OVER (PARTITION BY track_name, artist_names, released_year ORDER BY released_year DESC) as Duplicated_songs
FROM spotify_songs
ORDER BY Duplicated_songs DESC
)
SELECT f.track_name, f.artist_names, f.released_year, f.streams
FROM spotify_songs f
JOIN duplicated_tracks d
ON f.track_name = d.track_name
	AND f.artist_names = d.artist_names
    AND f.released_year = d.released_year
WHERE Duplicated_songs > 1
ORDER BY f.track_name, f.artist_names, f.streams, f.released_year;

# I noticed that their is one EXACT duplicate & then 3 extra duplicates with less stream values. I will be cleaning and removing the entries with lower stream values.
# Coming up with a way to delete one of those entries for `About Damn Time` by Lizzo. 
SELECT track_name, artist_names, released_year, streams,
	ROW_NUMBER() OVER (PARTITION BY track_name, artist_names, released_year, streams) AS Entry
FROM SPOTIFY_SONGS
WHERE track_name = 'About Damn Time'
	AND artist_names = 'Lizzo'
    AND released_year = 2022;
# Now that this query singles out the two About Damn Time Duplicates, I will delete either of them, however will be using Entry here as a key. If I didn't do this it would delete both.
# I noticed that they have different values for bpm, released_month etc. So i used those combinations as keys.

COMMIT;

SELECT * 
FROM SPOTIFY_SONGS
WHERE track_name = 'About Damn Time'
	AND artist_names = 'Lizzo'
    AND released_year = 2022;

DELETE FROM SPOTIFY_SONGS
WHERE track_name = 'About Damn Time'
	AND artist_names = 'Lizzo'
    AND released_year = 2022
    AND released_month = 4;

COMMIT;

# Now time to deal with the other duplicates. I'll be deleting the ones with the lesser values.

# Deleting SNAP by Rosa Linn
COMMIT;

SELECT COUNT(*)
FROM SPOTIFY_SONGS
WHERE track_name='SNAP'
	AND artist_names = 'Rosa Linn';

WITH to_delete AS (
SELECT *,
	ROW_NUMBER() OVER (PARTITION BY track_name, artist_names, released_year) as Indexed
FROM SPOTIFY_SONGS
WHERE track_name = 'SNAP'
	AND artist_names = 'Rosa Linn'
    AND released_year = '2022')
DELETE FROM SPOTIFY_SONGS
WHERE (artist_names, released_year, streams) IN (
	SELECT artist_names, released_year, streams
    FROM to_delete
    WHERE Indexed = 2
    );

# Deleting SPIT IN MY FACE! ny ThxSoMch
COMMIT;

WITH to_delete_2 as
(SELECT *,
	ROW_NUMBER() OVER (PARTITION BY track_name, artist_names, released_year) as Indexed
FROM SPOTIFY_SONGS
WHERE track_name = 'SPIT IN MY FACE!'
	AND artist_names = 'ThxSoMch'
    ORDER BY streams DESC
    )
DELETE FROM SPOTIFY_SONGS
WHERE (artist_names, released_year, streams) IN (
	SELECT artist_names, released_year, streams
    FROM to_delete_2
    WHERE Indexed = 2
    );
    
# Deleting Take My Breath by The Weeknd
COMMIT;
WITH to_Delete_3 AS 
(SELECT *,
	ROW_NUMBER() OVER (PARTITION BY track_name, artist_names, released_year) AS Indexed
FROM SPOTIFY_SONGS
WHERE track_name = 'Take My Breath'
	AND artist_names = 'The Weeknd'
    ORDER BY streams DESC
)
DELETE FROM SPOTIFY_SONGS
WHERE (artist_names, released_year, streams) IN (
	SELECT artist_names, released_year, streams
    FROM to_delete_3
    WHERE Indexed = 2
    );
    
# All duplicated tracks are gone

# Begining analysis

SELECT *
FROM SPOTIFY_SONGS;

# Which artist had the most solo songs in this dataset
SELECT artist_names, COUNT(artist_names) As Number_Of_Solo_Songs
FROM SPOTIFY_SONGS
GROUP BY artist_names
ORDER BY Number_Of_Solo_Songs DESC;

# Which artist had the most solo songs in this dataset in the range from 2020 - 2023
SELECT artist_names, COUNT(artist_names) AS Number_Of_Solo_Songs
FROM SPOTIFY_SONGS
WHERE released_year > 2019 AND released_year < 2024
GROUP BY artist_names
ORDER BY Number_Of_Solo_Songs DESC;

# The Top Song Per Year
SELECT released_year, track_name, artist_names, streams
FROM (
	SELECT released_year, track_name, artist_names, streams,
		ROW_NUMBER() OVER (PARTITION BY released_year ORDER BY streams DESC) as Ranking
	FROM SPOTIFY_SONGS
) as Domain
WHERE Ranking = 1
ORDER BY released_year DESC;

# Top artist by streams per year
SELECT released_year, artist_names, total
FROM (
	SELECT released_year, artist_names, sum(streams) AS total,
		ROW_NUMBER() OVER (PARTITION BY released_year ORDER BY sum(streams) DESC) AS Ranking
	FROM SPOTIFY_SONGS
	GROUP BY released_year, artist_names
) AS domain
WHERE Ranking = 1
ORDER BY released_year DESC;


# Number Of Each Artist Streams
SELECT artist_names, SUM(streams) As Most_Streams
FROM SPOTIFY_SONGS
GROUP BY artist_names
ORDER BY Most_Streams DESC;

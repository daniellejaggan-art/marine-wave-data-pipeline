#!/usr/bin/env python
# coding: utf-8

# In[47]:


import requests
import pandas as pd

url = "https://marine-api.open-meteo.com/v1/marine"

parameters = {
    "latitude":  54.544587,
    "longitude": 10.227487,
    "hourly":  "wave_height",
    "forecast_days":  7
}

response = requests.get(url, params=parameters)

print(response.status_code)

    


# In[48]:


data = response.json()

print(data)


# In[49]:


print(type(data))
print(data.keys())


# In[50]:


print(data["hourly"])


# In[51]:


print(data["hourly"]["wave_height"])


# In[52]:


print(type(data["hourly"]["wave_height"]))


# In[53]:


data["hourly"]["wave_height"][-5:]


# In[54]:


data["hourly"]["time"][0:5]


# In[55]:


time_stamp = data["hourly"]["time"]

wave = data["hourly"]["wave_height"]


# In[56]:


combined = zip(time_stamp, wave)

print(list(combined))


# In[57]:


combined = list(zip(time_stamp, wave))

df = pd.DataFrame(
    list(combined),
    columns=["timestamp", "wave_height"]
)

print(df.head())
print(df.shape)


# In[58]:


combined = list(zip(time_stamp, wave))


# In[59]:


print(len(combined))


# In[60]:


print(data["latitude"])
print(data["longitude"])
print(data["hourly_units"])


# In[61]:


print(data["timezone"])
print(data["timezone_abbreviation"])
print(data["utc_offset_seconds"])


# In[62]:


print(df.info())


# In[63]:


df["timestamp"] = pd.to_datetime(df["timestamp"])


# In[64]:


print(df["timestamp"])


# In[65]:


print(df.dtypes)


# In[66]:


df["latitude"] = data["latitude"]
df["longitude"] = data["longitude"]
df["timezone"] = data["timezone"]


# In[67]:


print(df.info())
print(df.head())
print(df.shape)


# In[68]:


metadata = {
    "wave_height_unit": data["hourly_units"]["wave_height"],
    "timezone": data["timezone"],
    "latitude": data["latitude"],
    "longitude": data["longitude"]
}


# In[69]:


print(metadata)


# In[70]:


print(df.isnull().sum())


# In[71]:


print(df.duplicated().sum())


# In[72]:


print(df["wave_height"].describe())


# In[73]:


print(df["timestamp"].min())
print(df["timestamp"].max())


# In[74]:


df["timestamp"].is_monotonic_increasing 


# In[75]:


df["timestamp"].diff().value_counts()


# In[76]:


import pandas as pd 
import sqlalchemy 


# In[79]:


from sqlalchemy import create_engine

engine = create_engine (
    "postgresql+psycopg2://postgres:Rowanda_2003@localhost:5432/marine_api_pipeline"
)


# In[80]:


df.to_sql(
    "raw_marine_api_pipeline",
    engine,
    if_exists="replace",
    index = "False"
)


# In[95]:


with engine.connect() as connection: 
    results = connection.execute(
        sqlalchemy.text("SELECT COUNT(*) FROM raw_marine_api_pipeline")
    )
print(result.scalar())


# In[96]:


with engine.connect() as connection:
    results = connection.execute(
        sqlalchemy.text("""
            SELECT
                COUNT(*) AS row_count,
                COUNT(*) FILTER (
                    WHERE wave_height IS NOT NULL
                ) AS wave_height_count
            FROM raw_marine_api_pipeline;
        """)
    )

    print(results.fetchone())


# In[102]:


with engine.connect() as connection:
    results = connection.execute(
        sqlalchemy.text("""
            SELECT
                COUNT(*) AS total_rows,
                COUNT(*) FILTER (
                    WHERE timestamp IS NULL
                ) AS missing_timestamps,
                COUNT(*) FILTER (
                    WHERE wave_height IS NULL
                ) AS missing_wave_heights,
                COUNT(DISTINCT timestamp) AS unique_timestamps
            FROM raw_marine_api_pipeline;
        """)
    )

    print(results.fetchone())


# In[100]:


with engine.connect() as connection:
    results = connection.execute(
        sqlalchemy.text("""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public';
        """)
    )

    for row in results:
        print(row[0])


# In[104]:


with engine.connect() as connection:
    results = connection.execute(
        sqlalchemy.text("""
            SELECT COUNT(*)
            FROM raw_marine_api_pipeline;
        """)
    )

    print("Raw records:", results.scalar())


# In[107]:


with engine.connect() as connection:
    print("Connection Successful")


# In[108]:


df.shape


# In[110]:


with engine.begin() as connection:
    connection.execute(
        sqlalchemy.text("""
            CREATE TABLE cleaned_marine_api_pipeline AS
            SELECT
                timestamp,
                wave_height,
                latitude,
                longitude,
                timezone
            FROM raw_marine_api_pipeline
            WHERE timestamp IS NOT NULL
              AND wave_height IS NOT NULL;
        """)
    )

print("Cleaned table created successfully!")


# In[ ]:





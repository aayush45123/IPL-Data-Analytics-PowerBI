import os
from dotenv import load_dotenv
import pandas as pd
import numpy as np
from sqlalchemy import create_engine


# Load the IPL dataset
df = pd.read_csv("IPL.csv", low_memory=False)

print("Dataset loaded successfully")


# Display the first few rows
print(df.head())


# Display the number of rows and columns
print(df.shape)


# Display all column names
print(df.columns.tolist())


# Display information about columns and data types
print(df.info())


# Check for missing values
print("\nMissing values:")
missing_values = df.isnull().sum()

print(missing_values[missing_values > 0])


# Check for duplicate rows
print("\nDuplicate rows:")
duplicate_count = df.duplicated().sum()

print(duplicate_count)


# Remove duplicate rows if they exist
if duplicate_count > 0:
    df = df.drop_duplicates()
    print("Duplicate rows removed")
else:
    print("No duplicate rows found")


# Clean column names
# Remove spaces from the beginning and end
# Convert names to lowercase
# Replace spaces with underscores

df.columns = (
    df.columns
    .str.strip()
    .str.lower()
    .str.replace(" ", "_")
)

print("\nCleaned column names:")
print(df.columns.tolist())


# Find all text columns
text_columns = df.select_dtypes(
    include=["object"]
).columns


# Remove unnecessary spaces from text values
for column in text_columns:
    df[column] = df[column].apply(
        lambda x: x.strip() if isinstance(x, str) else x
    )

print("\nExtra spaces removed from text columns")


# Convert the date column into proper date format
df["date"] = pd.to_datetime(
    df["date"],
    errors="coerce"
)

print("\nDate column converted successfully")


# Convert numeric columns into numeric data types
numeric_columns = [
    "match_id",
    "innings",
    "over",
    "ball",
    "ball_no",
    "bat_pos",
    "runs_batter",
    "balls_faced",
    "valid_ball",
    "runs_extras",
    "runs_total",
    "runs_bowler",
    "runs_not_boundary",
    "runs_target",
    "day",
    "month",
    "year",
    "balls_per_over",
    "team_runs",
    "team_balls",
    "team_wicket",
    "batter_runs",
    "batter_balls",
    "bowler_wicket"
]


for column in numeric_columns:
    if column in df.columns:
        df[column] = pd.to_numeric(
            df[column],
            errors="coerce"
        )

print("\nNumeric columns converted successfully")


# Check the data types after cleaning
print("\nData types after cleaning:")
print(df.dtypes)


# Check missing values after cleaning
print("\nMissing values after cleaning:")

missing_after_cleaning = df.isnull().sum()

print(
    missing_after_cleaning[
        missing_after_cleaning > 0
    ]
)


# Check duplicate rows after cleaning
print("\nDuplicate rows after cleaning:")
print(df.duplicated().sum())


# Display the final dataset shape
print("\nFinal dataset shape:")
print(df.shape)


# Save the cleaned dataset
# The original IPL.csv file will not be changed

df.to_csv(
    "IPL_Cleaned.csv",
    index=False
)

print("\nCleaned dataset saved as IPL_Cleaned.csv")


#intsall  pip install psycopg2-binary sqlalchemy 
#connect to postgresql database and create a table and insert the data into the table
load_dotenv()

username = 'postgres'
password = os.getenv('pass')  # get the password from .env file
host = 'localhost'
port = '5432'
database = 'Ipl'

engine = create_engine(
    f'postgresql+psycopg2://{username}:{password}@{host}:{port}/{database}'
)

table_name = 'ipl_data'

df.to_sql(
    table_name,
    engine,
    if_exists='replace',
    index=False
)

print(f"Data inserted into {table_name} table in {database} database successfully!")
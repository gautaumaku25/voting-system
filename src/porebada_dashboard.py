import streamlit as st
import pandas as pd
from datetime import datetime
import plotly.express as px
import psycopg2
import logging
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def get_db_connection():
    """Create a database connection"""
    try:
        # Try production settings first (Streamlit Cloud)
        try:
            conn = psycopg2.connect(
                host=st.secrets["postgres"]["host"],
                database=st.secrets["postgres"]["database"],
                user=st.secrets["postgres"]["user"],
                password=st.secrets["postgres"]["password"],
                port=st.secrets["postgres"]["port"]
            )
        # Fall back to local environment variables
        except Exception:
            conn = psycopg2.connect(
                host=os.getenv("DB_HOST"),
                database=os.getenv("DB_NAME"),
                user=os.getenv("DB_USER"),
                password=os.getenv("DB_PASSWORD"),
                port=os.getenv("DB_PORT")
            )
        return conn
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        st.error(f"Database Connection Error: {str(e)}")
        return None

def get_table_data(table_name):
    """Fetch data from specified table"""
    conn = get_db_connection()
    if conn is None:
        return pd.DataFrame()
    
    try:
        # Use parameterized query for better security
        query = "SELECT * FROM %s"
        df = pd.read_sql_query(query, conn, params=(table_name,))
        return df
    except Exception as e:
        logger.error(f"Error fetching data from {table_name}: {e}")
        st.error(f"Error fetching data: {str(e)}")
        return pd.DataFrame()
    finally:
        if conn:
            conn.close()

def insert_record(table_name, data):
    """Insert new record into database"""
    conn = get_db_connection()
    if conn is None:
        return False
    
    try:
        with conn.cursor() as cursor:
            columns = ', '.join(data.keys())
            placeholders = ', '.join(['%s'] * len(data))
            query = f"INSERT INTO {table_name} ({columns}) VALUES ({placeholders})"
            
            cursor.execute(query, list(data.values()))
            conn.commit()
            logger.info(f"Successfully inserted record into {table_name}")
            st.success("Record added successfully!")
            return True
    except Exception as e:
        if conn:
            conn.rollback()
        logger.error(f"Error inserting record: {e}")
        st.error(f"Error adding record: {str(e)}")
        return False
    finally:
        if conn:
            conn.close()

def update_record(table_name, seq, data):
    """Update existing record"""
    conn = get_db_connection()
    if conn is None:
        return False
    
    try:
        with conn.cursor() as cursor:
            set_values = ', '.join([f"{k} = %s" for k in data.keys()])
            query = f"UPDATE {table_name} SET {set_values} WHERE seq = %s"
            
            values = list(data.values()) + [seq]
            cursor.execute(query, values)
            conn.commit()
            
            logger.info(f"Successfully updated record {seq} in {table_name}")
            st.success("Record updated successfully!")
            return True
    except Exception as e:
        if conn:
            conn.rollback()
        logger.error(f"Error updating record: {e}")
        st.error(f"Error updating record: {str(e)}")
        return False
    finally:
        if conn:
            conn.close()

def delete_record(table_name, seq):
    """Delete record from database"""
    conn = get_db_connection()
    if conn is None:
        return False
    
    try:
        with conn.cursor() as cursor:
            query = f"DELETE FROM {table_name} WHERE seq = %s"
            cursor.execute(query, (seq,))
            conn.commit()
            
            logger.info(f"Successfully deleted record {seq} from {table_name}")
            st.success("Record deleted successfully!")
            return True
    except Exception as e:
        if conn:
            conn.rollback()
        logger.error(f"Error deleting record: {e}")
        st.error(f"Error deleting record: {str(e)}")
        return False
    finally:
        if conn:
            conn.close()

# The rest of your code (display_demographics_dashboard and main function) remains the same
# as they don't involve database connections

def main():
    st.set_page_config(page_title="Porebada Ward Dashboard", layout="wide")
    st.title("Porebada Ward Database Management System")

    # Test database connection
    conn = get_db_connection()
    if conn is None:
        st.error("Database connection failed. Please check the error messages above.")
        if st.button("Retry Connection"):
            st.experimental_rerun()
        return
    conn.close()

    # Rest of your main() function code remains the same...

if __name__ == "__main__":
    main()
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
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def get_db_connection():
    """Create a database connection"""
    try:
        logger.info("Attempting database connection...")
        
        # Check if we're running on Streamlit Cloud
        if hasattr(st, 'secrets'):
            logger.info("Using Streamlit Cloud configuration")
            connection_params = {
                'host': st.secrets["postgres"]["host"],
                'database': st.secrets["postgres"]["database"],
                'user': st.secrets["postgres"]["user"],
                'password': st.secrets["postgres"]["password"],
                'port': st.secrets["postgres"]["port"],
                'connect_timeout': 15,
                'sslmode': 'require'  # Important for cloud database connections
            }
        else:
            logger.info("Using local environment configuration")
            connection_params = {
                'host': os.getenv("DB_HOST"),
                'database': os.getenv("DB_NAME"),
                'user': os.getenv("DB_USER"),
                'password': os.getenv("DB_PASSWORD"),
                'port': os.getenv("DB_PORT"),
                'connect_timeout': 15
            }

        # Verify connection parameters
        missing_params = [k for k, v in connection_params.items() if not v]
        if missing_params:
            raise ValueError(f"Missing connection parameters: {', '.join(missing_params)}")

        # Log connection attempt (without sensitive info)
        logger.info(f"Connecting to database at {connection_params['host']}:{connection_params['port']}")
        
        conn = psycopg2.connect(**connection_params)
        
        # Test the connection
        with conn.cursor() as cursor:
            cursor.execute('SELECT 1')
            cursor.fetchone()
            
        logger.info("Database connection successful")
        return conn
        
    except psycopg2.OperationalError as e:
        logger.error(f"Database connection failed (Operational): {e}")
        if "could not connect to server" in str(e):
            st.error("Could not connect to database server. Please verify the host and port.")
        elif "password authentication failed" in str(e):
            st.error("Authentication failed. Please check your credentials.")
        else:
            st.error(f"Database connection failed: {str(e)}")
        return None
        
    except ValueError as e:
        logger.error(f"Configuration error: {e}")
        st.error(str(e))
        return None
        
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        st.error(f"An unexpected error occurred: {str(e)}")
        return None

def get_table_data(table_name):
    """Fetch data from specified table"""
    conn = get_db_connection()
    if conn is None:
        return pd.DataFrame()
    
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(f"SELECT * FROM {table_name}")
            data = cursor.fetchall()
            df = pd.DataFrame(data)
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

def display_demographics_dashboard():
    """Display demographics dashboard"""
    st.header("Demographics Dashboard")
    
    # Fetch data
    df = get_table_data('demographics')
    if df.empty:
        st.warning("No data available to display")
        return
    
    # Display statistics
    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric("Total Population", df['population'].sum())
    with col2:
        st.metric("Average Age", f"{df['average_age'].mean():.1f}")
    with col3:
        st.metric("Number of Households", df['households'].sum())
    
    # Create visualizations
    st.subheader("Population Distribution")
    fig = px.bar(df, x='area', y='population', title='Population by Area')
    st.plotly_chart(fig)
    
    # Age distribution
    st.subheader("Age Distribution")
    fig = px.pie(df, values='population', names='age_group', title='Population by Age Group')
    st.plotly_chart(fig)

def main():
    st.set_page_config(page_title="Porebada Ward Dashboard", layout="wide")
    st.title("Porebada Ward Database Management System")

    # Test database connection
    with st.spinner("Connecting to database..."):
        conn = get_db_connection()
        
    if conn is None:
        st.error("Database connection failed. Please check the error messages above.")
        if st.button("Retry Connection"):
            st.experimental_rerun()
        return
    
    try:
        conn.close()
        st.success("Database connection successful!")
    except Exception:
        pass

    # Sidebar navigation
    st.sidebar.title("Navigation")
    page = st.sidebar.selectbox(
        "Select a page",
        ["Demographics Dashboard", "Data Management"]
    )

    if page == "Demographics Dashboard":
        display_demographics_dashboard()
    else:
        st.header("Data Management")
        # Add your data management UI here

if __name__ == "__main__":
    main()
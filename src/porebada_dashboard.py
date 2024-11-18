import streamlit as st
import pandas as pd
from datetime import datetime
import plotly.express as px
import psycopg2
import logging
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv
import os
from typing import Optional, Dict, Any

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize session state
if 'data_changed' not in st.session_state:
    st.session_state.data_changed = False

class DatabaseConnection:
    @staticmethod
    def get_connection_params() -> Dict[str, Any]:
        """Get database connection parameters based on environment"""
        if hasattr(st, 'secrets'):
            logger.info("Using Streamlit Cloud configuration")
            return {
                'host': st.secrets["postgres"]["host"],
                'database': st.secrets["postgres"]["database"],
                'user': st.secrets["postgres"]["user"],
                'password': st.secrets["postgres"]["password"],
                'port': st.secrets["postgres"]["port"],
                'connect_timeout': 15,
                'sslmode': 'require'
            }
        else:
            logger.info("Using local environment configuration")
            return {
                'host': os.getenv("DB_HOST"),
                'database': os.getenv("DB_NAME"),
                'user': os.getenv("DB_USER"),
                'password': os.getenv("DB_PASSWORD"),
                'port': os.getenv("DB_PORT"),
                'connect_timeout': 15
            }

    @staticmethod
    def get_connection() -> Optional[psycopg2.extensions.connection]:
        """Create and return a database connection"""
        try:
            connection_params = DatabaseConnection.get_connection_params()
            
            # Verify connection parameters
            missing_params = [k for k, v in connection_params.items() if not v]
            if missing_params:
                raise ValueError(f"Missing connection parameters: {', '.join(missing_params)}")
            
            conn = psycopg2.connect(**connection_params)
            
            # Test connection
            with conn.cursor() as cursor:
                cursor.execute('SELECT 1')
                cursor.fetchone()
                
            logger.info("Database connection successful")
            return conn
            
        except (psycopg2.OperationalError, ValueError) as e:
            DatabaseConnection.handle_connection_error(e)
            return None
            
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            st.error(f"An unexpected error occurred: {str(e)}")
            return None

    @staticmethod
    def handle_connection_error(error: Exception) -> None:
        """Handle database connection errors"""
        if isinstance(error, psycopg2.OperationalError):
            logger.error(f"Database connection failed (Operational): {error}")
            if "could not connect to server" in str(error):
                st.error("Could not connect to database server. Please verify the host and port.")
            elif "password authentication failed" in str(error):
                st.error("Authentication failed. Please check your credentials.")
            else:
                st.error(f"Database connection failed: {str(error)}")
        elif isinstance(error, ValueError):
            logger.error(f"Configuration error: {error}")
            st.error(str(error))

class DatabaseOperations:
    @staticmethod
    def get_table_data(table_name: str) -> pd.DataFrame:
        """Fetch data from specified table"""
        conn = DatabaseConnection.get_connection()
        if conn is None:
            return pd.DataFrame()
        
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(f"SELECT * FROM {table_name}")
                data = cursor.fetchall()
                return pd.DataFrame(data)
        except Exception as e:
            logger.error(f"Error fetching data from {table_name}: {e}")
            st.error(f"Error fetching data: {str(e)}")
            return pd.DataFrame()
        finally:
            if conn:
                conn.close()

    @staticmethod
    def insert_record(table_name: str, data: Dict[str, Any]) -> bool:
        """Insert new record into database"""
        conn = DatabaseConnection.get_connection()
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
                st.session_state.data_changed = True
                return True
        except Exception as e:
            DatabaseOperations.handle_database_error(conn, e, "inserting")
            return False
        finally:
            if conn:
                conn.close()

    @staticmethod
    def update_record(table_name: str, seq: int, data: Dict[str, Any]) -> bool:
        """Update existing record"""
        conn = DatabaseConnection.get_connection()
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
                st.session_state.data_changed = True
                return True
        except Exception as e:
            DatabaseOperations.handle_database_error(conn, e, "updating")
            return False
        finally:
            if conn:
                conn.close()

    @staticmethod
    def delete_record(table_name: str, seq: int) -> bool:
        """Delete record from database"""
        conn = DatabaseConnection.get_connection()
        if conn is None:
            return False
        
        try:
            with conn.cursor() as cursor:
                query = f"DELETE FROM {table_name} WHERE seq = %s"
                cursor.execute(query, (seq,))
                conn.commit()
                
                logger.info(f"Successfully deleted record {seq} from {table_name}")
                st.success("Record deleted successfully!")
                st.session_state.data_changed = True
                return True
        except Exception as e:
            DatabaseOperations.handle_database_error(conn, e, "deleting")
            return False
        finally:
            if conn:
                conn.close()

    @staticmethod
    def handle_database_error(conn: Optional[psycopg2.extensions.connection], 
                            error: Exception, operation: str) -> None:
        """Handle database operation errors"""
        if conn:
            conn.rollback()
        logger.error(f"Error {operation} record: {error}")
        st.error(f"Error {operation} record: {str(error)}")

class DemographicsDashboard:
    def display(self):
        """Display demographics dashboard"""
        st.header("Demographics Dashboard")
        
        # Fetch data
        df = DatabaseOperations.get_table_data('demographics')
        if df.empty:
            st.warning("No data available to display")
            return
        
        self._display_metrics(df)
        self._display_charts(df)
        self._display_data_table(df)

    def _display_metrics(self, df: pd.DataFrame):
        """Display key metrics"""
        col1, col2, col3 = st.columns(3)
        with col1:
            st.metric("Total Population", f"{df['population'].sum():,}")
        with col2:
            st.metric("Average Age", f"{df['average_age'].mean():.1f}")
        with col3:
            st.metric("Total Households", f"{df['households'].sum():,}")

    def _display_charts(self, df: pd.DataFrame):
        """Display visualizations"""
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("Population by Area")
            fig = px.bar(df, x='area', y='population',
                        title='Population Distribution')
            st.plotly_chart(fig, use_container_width=True)
            
        with col2:
            st.subheader("Age Distribution")
            fig = px.pie(df, values='population', names='age_group',
                        title='Population by Age Group')
            st.plotly_chart(fig, use_container_width=True)

    def _display_data_table(self, df: pd.DataFrame):
        """Display interactive data table"""
        st.subheader("Demographic Data")
        st.dataframe(
            df.style.format({
                'population': '{:,}',
                'households': '{:,}',
                'average_age': '{:.1f}'
            })
        )

def main():
    # Page configuration
    st.set_page_config(
        page_title="Porebada Ward Dashboard",
        page_icon="📊",
        layout="wide"
    )
    st.title("Porebada Ward Database Management System")

    # Test database connection
    with st.spinner("Connecting to database..."):
        conn = DatabaseConnection.get_connection()
        
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

    # Display selected page
    if page == "Demographics Dashboard":
        dashboard = DemographicsDashboard()
        dashboard.display()
    else:
        st.header("Data Management")
        # Add your data management UI here

if __name__ == "__main__":
    main()
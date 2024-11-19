import streamlit as st
import pandas as pd
import plotly.express as px
import psycopg2
import logging
from psycopg2.extras import RealDictCursor
from typing import Optional, Dict, Any

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
        """Get database connection parameters from Streamlit secrets"""
        try:
            return {
                'host': st.secrets["postgres"]["host"],
                'database': st.secrets["postgres"]["database"],
                'user': st.secrets["postgres"]["user"],
                'password': st.secrets["postgres"]["password"],
                'port': st.secrets["postgres"]["port"],
                'connect_timeout': 15,
                'sslmode': 'require'
            }
        except Exception as e:
            logger.error(f"Error reading secrets: {e}")
            st.error("Error reading database configuration. Please check your secrets.toml file.")
            return {}

    @staticmethod
    def get_connection() -> Optional[psycopg2.extensions.connection]:
        """Create and return a database connection"""
        try:
            connection_params = DatabaseConnection.get_connection_params()
            if not connection_params:
                return None
                
            conn = psycopg2.connect(**connection_params)
            
            # Test connection
            with conn.cursor() as cursor:
                cursor.execute('SELECT 1')
                cursor.fetchone()
                
            logger.info("Database connection successful")
            return conn
            
        except psycopg2.OperationalError as e:
            logger.error(f"Database connection failed: {e}")
            st.error("Could not connect to database. Please check your connection settings.")
            return None
            
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            st.error(f"An unexpected error occurred: {str(e)}")
            return None

class DatabaseOperations:
    @staticmethod
    def get_ward_demographics() -> pd.DataFrame:
        """Fetch data from porebada_ward_demographics view"""
        conn = DatabaseConnection.get_connection()
        if conn is None:
            return pd.DataFrame()
        
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("SELECT * FROM porebada_ward_demographics")
                data = cursor.fetchall()
                return pd.DataFrame(data)
        except Exception as e:
            logger.error(f"Error fetching ward demographics: {e}")
            st.error(f"Error fetching data: {str(e)}")
            return pd.DataFrame()
        finally:
            if conn:
                conn.close()

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
        """Insert a new record into specified table"""
        conn = DatabaseConnection.get_connection()
        if conn is None:
            return False

        try:
            columns = ', '.join(data.keys())
            values = ', '.join([f"%({k})s" for k in data.keys()])
            query = f"INSERT INTO {table_name} ({columns}) VALUES ({values})"
            
            with conn.cursor() as cursor:
                cursor.execute(query, data)
            conn.commit()
            st.success("Record added successfully!")
            return True
        except Exception as e:
            logger.error(f"Error inserting record: {e}")
            st.error(f"Error inserting record: {str(e)}")
            return False
        finally:
            if conn:
                conn.close()

class DemographicsDashboard:
    def display(self):
        """Display complete dashboard"""
        # Create tabs for different sections
        tab_main, tab_details, tab_entry = st.tabs([
            "Main Dashboard",
            "Detailed Records",
            "Data Entry"
        ])
        
        with tab_main:
            st.header("Porebada Ward Demographics")
            # Fetch and display main dashboard
            df = DatabaseOperations.get_ward_demographics()
            if df.empty:
                st.warning("No data available to display")
                return
            
            self._display_metrics(df)
            self._display_charts(df)
            self._display_data_table(df)
            
        with tab_details:
            self._display_detailed_tables()
            
        with tab_entry:
            self._display_data_entry()

    def _display_metrics(self, df: pd.DataFrame):
        """Display key metrics"""
        total_population = df['total_population'].sum()
        total_male = df['male_population'].sum()
        total_female = df['female_population'].sum()
        working_age = df['age_15_64'].sum()
        
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            st.metric("Total Population", f"{total_population:,}")
        with col2:
            st.metric("Male Population", f"{total_male:,}")
        with col3:
            st.metric("Female Population", f"{total_female:,}")
        with col4:
            st.metric("Working Age (15-64)", f"{working_age:,}")

    def _display_charts(self, df: pd.DataFrame):
        """Display visualizations"""
        col1, col2 = st.columns(2)
        
        with col1:
            # Gender distribution by ward
            fig_gender = px.bar(
                df,
                x='ward_id',
                y=['male_population', 'female_population'],
                title='Population by Gender and Ward',
                barmode='group',
                labels={'value': 'Population', 'variable': 'Gender'},
                color_discrete_sequence=['#1f77b4', '#ff7f0e']
            )
            st.plotly_chart(fig_gender, use_container_width=True)
        
        with col2:
            # Age distribution by ward
            age_data = pd.melt(
                df,
                id_vars=['ward_id'],
                value_vars=['age_0_14', 'age_15_64', 'age_65_plus'],
                var_name='Age Group',
                value_name='Population'
            )
            fig_age = px.bar(
                age_data,
                x='ward_id',
                y='Population',
                color='Age Group',
                title='Age Distribution by Ward',
                barmode='stack'
            )
            st.plotly_chart(fig_age, use_container_width=True)

    def _display_data_table(self, df: pd.DataFrame):
        """Display interactive data table"""
        st.subheader("Detailed Demographics Data")
        
        # Format numeric columns
        formatted_df = df.copy()
        numeric_cols = ['total_population', 'male_population', 'female_population', 
                       'age_0_14', 'age_15_64', 'age_65_plus', 
                       'household_count', 'avg_household_size', 'population_density']
        
        for col in numeric_cols:
            if col in formatted_df.columns:
                formatted_df[col] = formatted_df[col].apply(lambda x: f"{x:,.0f}" if pd.notnull(x) else "N/A")
        
        st.dataframe(formatted_df, use_container_width=True)

    def _display_detailed_tables(self):
        """Display individual demographic tables"""
        st.subheader("Detailed Population Records")
        
        tab1, tab2, tab3 = st.tabs([
            "East Ward - Female", 
            "East Ward - Male",
            "West Ward - Male & Female"
        ])
        
        with tab1:
            df_east_female = DatabaseOperations.get_table_data("porebada_east_female")
            st.dataframe(df_east_female, use_container_width=True)
            
        with tab2:
            df_east_male = DatabaseOperations.get_table_data("porebada_east_male")
            st.dataframe(df_east_male, use_container_width=True)
            
        with tab3:
            df_west = DatabaseOperations.get_table_data("porebada_west_male_female")
            st.dataframe(df_west, use_container_width=True)

    def _display_data_entry(self):
        """Display data entry forms for all tables"""
        st.subheader("Data Entry")
        
        table_choice = st.selectbox(
            "Select table for data entry",
            ["porebada_east_female", "porebada_east_male", "porebada_west_male_female"]
        )

        with st.form(f"data_entry_form_{table_choice}"):
            st.write(f"Enter data for {table_choice}")
            
            # Fields based on the database schema
            electoral_id = st.text_input("Electoral ID")
            name = st.text_input("Name")
            gender = st.selectbox("Gender", ["F", "M"])
            location = st.selectbox("Location", ["POREBADA EAST", "POREBADA WEST"])
            occupation = st.text_input("Occupation")
            dob = st.date_input("Date of Birth")
            
            submitted = st.form_submit_button("Submit")
            
            if submitted:
                # Convert date to DD-Mon-YYYY format
                dob_formatted = dob.strftime("%d-%b-%Y")  # This will format like "07-Jun-2002"
                
                data = {
                    "electoral_id": electoral_id,
                    "name": name,
                    "gender": gender,
                    "location": location,
                    "occupation": occupation,
                    "dob": dob_formatted
                }
                
                if DatabaseOperations.insert_record(table_choice, data):
                    st.session_state.data_changed = True

def main():
    # Page configuration
    st.set_page_config(
        page_title="Porebada Ward Dashboard",
        page_icon="📊",
        layout="wide"
    )
    st.title("Porebada Ward Demographics Dashboard")

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

    # Display dashboard
    dashboard = DemographicsDashboard()
    dashboard.display()

if __name__ == "__main__":
    main()
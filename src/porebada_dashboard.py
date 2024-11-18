import streamlit as st
import pandas as pd
from datetime import datetime
import plotly.express as px
import psycopg2
import logging
from psycopg2.extras import RealDictCursor

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database connection configuration
DB_CONFIG = {
    "dbname": "porebada_ward",
    "user": "postgres",
    "password": "Philly22061998@@@",
    "host": "localhost",
    "port": "5432"
}

def get_db_connection():
    """Create a database connection"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
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
        query = f"SELECT * FROM {table_name}"
        df = pd.read_sql_query(query, conn)
        conn.close()
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
        cursor = conn.cursor()
        columns = ', '.join(data.keys())
        values = ', '.join(['%s'] * len(data))
        query = f"INSERT INTO {table_name} ({columns}) VALUES ({values})"
        
        cursor.execute(query, list(data.values()))
        conn.commit()
        logger.info(f"Successfully inserted record into {table_name}")
        st.success("Record added successfully!")
        return True
    except Exception as e:
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
        cursor = conn.cursor()
        set_values = ', '.join([f"{k} = %s" for k in data.keys()])
        query = f"UPDATE {table_name} SET {set_values} WHERE seq = %s"
        
        values = list(data.values()) + [seq]
        cursor.execute(query, values)
        conn.commit()
        
        logger.info(f"Successfully updated record {seq} in {table_name}")
        st.success("Record updated successfully!")
        return True
    except Exception as e:
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
        cursor = conn.cursor()
        query = f"DELETE FROM {table_name} WHERE seq = %s"
        cursor.execute(query, (seq,))
        conn.commit()
        
        logger.info(f"Successfully deleted record {seq} from {table_name}")
        st.success("Record deleted successfully!")
        return True
    except Exception as e:
        conn.rollback()
        logger.error(f"Error deleting record: {e}")
        st.error(f"Error deleting record: {str(e)}")
        return False
    finally:
        if conn:
            conn.close()

def display_demographics_dashboard(df):
    """Display demographics visualizations"""
    st.subheader("Demographics Analysis")
    
    try:
        # Gender distribution
        if 'gender' in df.columns:
            gender_dist = df['gender'].value_counts()
            fig_gender = px.pie(values=gender_dist.values, names=gender_dist.index, 
                              title="Gender Distribution")
            st.plotly_chart(fig_gender)
        
        # Age distribution
        if 'dob' in df.columns:
            df['age'] = pd.to_datetime('now').year - pd.to_datetime(df['dob']).dt.year
            fig_age = px.histogram(df, x='age', title="Age Distribution")
            st.plotly_chart(fig_age)
        
        # Occupation distribution
        if 'occupation' in df.columns:
            occupation_dist = df['occupation'].value_counts()
            fig_occupation = px.bar(x=occupation_dist.index, y=occupation_dist.values,
                                  title="Occupation Distribution")
            st.plotly_chart(fig_occupation)
    
    except Exception as e:
        logger.error(f"Error generating demographics dashboard: {e}")
        st.error(f"Error generating visualizations: {str(e)}")

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

    # Available tables
    tables = [
        "porebada_east_male",
        "porebada_east_female",
        "porebada_west_male_female",
        "porebada_ward_economics",
        "porebada_ward_education",
        "porebada_ward_health",
        "porebada_ward_infrastructure"
    ]
    
    # Sidebar
    st.sidebar.title("Navigation")
    selected_table = st.sidebar.selectbox("Select Table", tables)
    
    # Main content area
    df = get_table_data(selected_table)
    
    # Add new record section
    st.subheader("Add New Record")
    with st.expander("Add New Record Form"):
        if selected_table in ["porebada_east_male", "porebada_east_female", "porebada_west_male_female"]:
            col1, col2, col3 = st.columns(3)
            with col1:
                electoral_id = st.text_input("Electoral ID")
                name = st.text_input("Name")
                gender = st.selectbox("Gender", ["M", "F"])
            with col2:
                location = st.text_input("Location")
                occupation = st.text_input("Occupation")
            with col3:
                dob = st.date_input("Date of Birth")
            
            if st.button("Add Record"):
                if all([electoral_id, name, gender, location, occupation, dob]):
                    new_data = {
                        "electoral_id": electoral_id,
                        "name": name,
                        "gender": gender,
                        "location": location,
                        "occupation": occupation,
                        "dob": dob
                    }
                    if insert_record(selected_table, new_data):
                        st.experimental_rerun()
                else:
                    st.warning("Please fill in all fields")

    # Display and edit existing records
    st.subheader("Existing Records")
    if not df.empty:
        edited_df = st.data_editor(df, key="data_editor", num_rows="dynamic")
        
        if st.button("Save Changes"):
            try:
                changes = edited_df != df
                changed_rows = changes.any(axis=1)
                
                if changed_rows.any():
                    for idx in changed_rows[changed_rows].index:
                        seq = edited_df.loc[idx, 'seq']
                        row_data = edited_df.loc[idx].to_dict()
                        row_data.pop('seq', None)  # Remove seq from update data
                        if update_record(selected_table, seq, row_data):
                            continue
                    st.experimental_rerun()
                else:
                    st.info("No changes detected")
            except Exception as e:
                logger.error(f"Error saving changes: {e}")
                st.error(f"Error saving changes: {str(e)}")
    else:
        st.info("No records found in the selected table")

    # Demographics dashboard
    if selected_table in ["porebada_east_male", "porebada_east_female", "porebada_west_male_female"]:
        if not df.empty:
            display_demographics_dashboard(df)
        else:
            st.warning("No data available for demographics analysis")

if __name__ == "__main__":
    main()
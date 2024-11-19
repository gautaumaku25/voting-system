import streamlit as st
import pandas as pd
import psycopg2
from datetime import datetime
import pytz
from hashlib import sha256
import numpy as np
from datetime import date

# Set Papua New Guinea timezone
PNG_TZ = pytz.timezone('Pacific/Port_Moresby')

# Initialize connection
def init_connection():
    return psycopg2.connect(
        host=st.secrets["postgres"]["host"],
        database=st.secrets["postgres"]["database"],
        user=st.secrets["postgres"]["user"],
        password=st.secrets["postgres"]["password"],
        port=st.secrets["postgres"]["port"]
    )

# Format date to match database format with PNG timezone
def format_date(date_obj):
    png_date = datetime.now(PNG_TZ).replace(
        year=date_obj.year,
        month=date_obj.month,
        day=date_obj.day
    )
    return png_date.strftime("%d-%b-%Y")

# Fetch voter data
def get_voter_data():
    conn = init_connection()
    tables = ['porebada_east_male', 'porebada_east_female', 'porebada_west_male_female']
    voters = []
    
    for table in tables:
        query = f"SELECT name, dob, electoral_id FROM {table}"
        df = pd.read_sql_query(query, conn)
        voters.append(df)
    
    conn.close()
    return pd.concat(voters, ignore_index=True)

# Initialize database tables for voting
def init_database():
    conn = init_connection()
    cur = conn.cursor()
    
    cur.execute("""
        CREATE TABLE IF NOT EXISTS candidates (
            id SERIAL PRIMARY KEY,
            name VARCHAR(100) UNIQUE NOT NULL
        )
    """)
    
    cur.execute("""
        CREATE TABLE IF NOT EXISTS votes (
            id SERIAL PRIMARY KEY,
            voter_name VARCHAR(100) NOT NULL,
            electoral_id VARCHAR(20) NOT NULL,
            candidate_1 INTEGER REFERENCES candidates(id),
            candidate_2 INTEGER REFERENCES candidates(id),
            candidate_3 INTEGER REFERENCES candidates(id),
            timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (NOW() AT TIME ZONE 'Pacific/Port_Moresby')
        )
    """)
    
    conn.commit()
    conn.close()

def add_sample_candidates():
    conn = init_connection()
    cur = conn.cursor()
    
    cur.execute("SELECT COUNT(*) FROM candidates")
    count = cur.fetchone()[0]
    
    if count == 0:
        sample_candidates = [
            "John Smith",
            "Mary Johnson",
            "David Williams",
            "Sarah Brown",
            "Michael Davis"
        ]
        
        for candidate in sample_candidates:
            cur.execute("INSERT INTO candidates (name) VALUES (%s)", (candidate,))
    
    conn.commit()
    conn.close()

def verify_voter(name, dob):
    voters_df = get_voter_data()
    formatted_dob = format_date(dob)
    return voters_df[
        (voters_df['name'].str.lower() == name.lower()) & 
        (voters_df['dob'] == formatted_dob)
    ]

def cast_vote(voter_name, electoral_id, pref1, pref2, pref3):
    current_time = datetime.now(PNG_TZ)
    
    conn = init_connection()
    cur = conn.cursor()
    
    cur.execute("""
        INSERT INTO votes (voter_name, electoral_id, candidate_1, candidate_2, candidate_3, timestamp)
        VALUES (%s, %s, %s, %s, %s, %s)
    """, (voter_name, electoral_id, pref1, pref2, pref3, current_time))
    
    conn.commit()
    conn.close()

def has_voted(electoral_id):
    conn = init_connection()
    cur = conn.cursor()
    
    cur.execute("SELECT COUNT(*) FROM votes WHERE electoral_id = %s", (electoral_id,))
    count = cur.fetchone()[0]
    
    conn.close()
    return count > 0

def get_results():
    conn = init_connection()
    cur = conn.cursor()
    
    cur.execute("SELECT id, name FROM candidates")
    candidates = dict(cur.fetchall())
    
    preferences = {}
    for i in range(1, 4):
        cur.execute(f"""
            SELECT candidate_{i}, COUNT(*) 
            FROM votes 
            GROUP BY candidate_{i}
            ORDER BY COUNT(*) DESC
        """)
        preferences[i] = {candidates[row[0]]: row[1] for row in cur.fetchall()}
    
    cur.execute("""
        SELECT voter_name, 
               c1.name as pref1, 
               c2.name as pref2, 
               c3.name as pref3, 
               timestamp
        FROM votes v
        JOIN candidates c1 ON v.candidate_1 = c1.id
        JOIN candidates c2 ON v.candidate_2 = c2.id
        JOIN candidates c3 ON v.candidate_3 = c3.id
        ORDER BY timestamp DESC
    """)
    history = cur.fetchall()
    
    conn.close()
    return preferences, history

def main():
    st.set_page_config(page_title="LPV Voting System", layout="wide")
    
    init_database()
    add_sample_candidates()
    
    current_png_time = datetime.now(PNG_TZ).strftime("%Y-%m-%d %H:%M:%S %Z")
    st.sidebar.write(f"Current PNG Time: {current_png_time}")
    
    page = st.sidebar.radio("Navigation", ["Login", "Results"])
    
    if page == "Login":
        st.title("LPV Voting System - Login")
        
        with st.form("voter_login"):
            name = st.text_input("Full Name")
            
            max_date = datetime.now(PNG_TZ).date()
            min_date = date(1924, 1, 1)
            default_date = date(1970, 1, 1)
            
            dob = st.date_input(
                "Date of Birth",
                min_value=min_date,
                max_value=max_date,
                value=default_date,
                help="Format: DD-Mon-YYYY (e.g., 06-May-1970)"
            )
            
            st.caption(f"Selected date in required format: {format_date(dob)}")
            
            submit = st.form_submit_button("Login")
            
            if submit:
                voter = verify_voter(name, dob)
                if not voter.empty:
                    electoral_id = voter.iloc[0]['electoral_id']
                    
                    if has_voted(electoral_id):
                        st.error("You have already cast your vote!")
                    else:
                        st.session_state['voter'] = {
                            'name': name,
                            'electoral_id': electoral_id
                        }
                        st.success("Login successful! Please proceed to vote.")
                        st.experimental_rerun()
                else:
                    st.error("Invalid voter credentials!")
        
        if 'voter' in st.session_state:
            st.subheader("Cast Your Vote")
            
            conn = init_connection()
            cur = conn.cursor()
            cur.execute("SELECT id, name FROM candidates")
            candidates = cur.fetchall()
            conn.close()
            
            with st.form("voting_form"):
                st.write("Select your preferences (all three must be different):")
                pref1 = st.selectbox("1st Preference", candidates, format_func=lambda x: x[1])
                pref2 = st.selectbox("2nd Preference", candidates, format_func=lambda x: x[1])
                pref3 = st.selectbox("3rd Preference", candidates, format_func=lambda x: x[1])
                
                vote_submit = st.form_submit_button("Cast Vote")
                
                if vote_submit:
                    if len({pref1[0], pref2[0], pref3[0]}) != 3:
                        st.error("Please select different candidates for each preference!")
                    else:
                        cast_vote(
                            st.session_state['voter']['name'],
                            st.session_state['voter']['electoral_id'],
                            pref1[0], pref2[0], pref3[0]
                        )
                        st.success("Vote cast successfully!")
                        del st.session_state['voter']
                        st.experimental_rerun()
    
    else:  # Results page
        st.title("Voting Results")
        
        preferences, history = get_results()
        
        col1, col2, col3 = st.columns(3)
        
        with col1:
            st.subheader("1st Preference Counts")
            if preferences[1]:
                st.bar_chart(preferences[1])
        
        with col2:
            st.subheader("2nd Preference Counts")
            if preferences[2]:
                st.bar_chart(preferences[2])
        
        with col3:
            st.subheader("3rd Preference Counts")
            if preferences[3]:
                st.bar_chart(preferences[3])
        
        st.subheader("Voting History")
        if history:
            df = pd.DataFrame(
                history,
                columns=['Voter Name', 'Preference 1', 'Preference 2', 'Preference 3', 'Timestamp']
            )
            df['Timestamp'] = pd.to_datetime(df['Timestamp']).dt.tz_convert('Pacific/Port_Moresby')
            st.dataframe(df)

if __name__ == "__main__":
    main()
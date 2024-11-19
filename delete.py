import psycopg2
import streamlit as st

def clear_voting_data():
    conn = psycopg2.connect(
        host=st.secrets["postgres"]["host"],
        database=st.secrets["postgres"]["database"],
        user=st.secrets["postgres"]["user"],
        password=st.secrets["postgres"]["password"],
        port=st.secrets["postgres"]["port"]
    )
    cur = conn.cursor()
    
    # Delete all votes and reset sequence
    cur.execute("TRUNCATE TABLE votes CASCADE;")
    cur.execute("ALTER SEQUENCE votes_id_seq RESTART WITH 1;")
    
    conn.commit()
    print("All voting data has been successfully deleted.")
    cur.close()
    conn.close()

if __name__ == "__main__":
    clear_voting_data()
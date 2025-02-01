import requests
import pandas as pd
import streamlit as st
from datetime import datetime
import os
import time

st.set_page_config(
    page_title="Painel de Sensores",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Configuração das URLs
urls = {
    "Sensor 1": "http://192.168.15.25/dados",
    "Sensor 2": "http://192.168.15.24/dados"
}

# Nome do arquivo para salvar os dados
csv_file = "historico_sensores.csv"

# Verifica se o arquivo existe
if os.path.exists(csv_file):
    historical_data = pd.read_csv(csv_file, parse_dates=['timestamp'])
else:
    historical_data = pd.DataFrame(columns=['sensor', 'temperatura', 'umidade', 'timestamp'])

def fetch_data(url):
    """Busca os dados da API."""
    try:
        response = requests.get(url, timeout=5)
        response.raise_for_status()
        data = response.json()
        data['timestamp'] = datetime.now()  # Adiciona o timestamp atual
        return data
    except Exception as e:
        st.warning(f"Erro ao acessar {url}: {e}")
        return None

def save_data(sensor, data):
    """Salva os dados em um arquivo CSV."""
    global historical_data
    data['sensor'] = sensor
    new_data = pd.DataFrame([data])
    historical_data = pd.concat([historical_data, new_data], ignore_index=True)
    historical_data.to_csv(csv_file, index=False)

# Interface do Streamlit
st.title("Painel de Sensores")
st.markdown("### Dados em Tempo Real")

placeholder = st.empty()  # Placeholder para atualizar os dados dinamicamente

while True:
    for sensor, url in urls.items():
        data = fetch_data(url)
        if data:
            save_data(sensor, data)
    
    with placeholder.container():
        # Atualiza e exibe os dados em tempo real
        for sensor in urls.keys():
            st.markdown(f"**{sensor}:**")
            latest_data = historical_data[historical_data['sensor'] == sensor].tail(1)
            if not latest_data.empty:
                latest_data = latest_data.iloc[0]
                st.write(f"Temperatura: {latest_data['temperatura']} °C")
                st.write(f"Umidade: {latest_data['umidade']} %")
                st.write(f"Última atualização: {latest_data['timestamp']}")
            else:
                st.warning(f"Sem dados para {sensor}")

        # Histórico
        st.markdown("### Histórico de Dados")
        for sensor in urls.keys():
            st.markdown(f"**Histórico - {sensor}**")
            df = historical_data[historical_data['sensor'] == sensor]
            if not df.empty:
                df['timestamp'] = pd.to_datetime(df['timestamp'])
                df = df.set_index('timestamp')
                st.line_chart(df[['temperatura', 'umidade']])
                st.dataframe(df)
            else:
                st.warning(f"Sem histórico disponível para {sensor}")
    
    # Atualiza os dados a cada 5 segundos
    time.sleep(5)

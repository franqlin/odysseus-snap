from mitmproxy import http
from datetime import datetime

def request(flow: http.HTTPFlow) -> None:
    # Verifica se é uma requisição de clique em um link
    if (
        "Referer" in flow.request.headers  # Tem cabeçalho Referer (indicando que veio de uma página anterior)
        and flow.request.method == "GET"   # Método GET
        and not flow.request.headers.get("Content-Type", "").startswith(("text/css", "image/", "application/javascript"))  # Exclui recursos secundários
        and not any(ext in flow.request.pretty_url for ext in [".js", ".css", ".png", ".jpg", ".gif", ".ico", ".svg",".mp4"])  # Exclui recursos secundários
    ):
        # Loga a requisição de clique em um link
        log_message = f"Data e Hora: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
        log_message += f"link: {flow.request.pretty_url}\n"
        log_message += f"Referer: {flow.request.headers['Referer']}\n"
        #log_message += f"Cabeçalho: {flow.request.headers}\n\n"
        
        # Escreve no arquivo request.txt
        with open("./requests.txt", "a") as file:
            file.write(log_message)
        
        # Exemplo de modificação da requisição
        flow.request.headers["X-Link-Click"] = "True"

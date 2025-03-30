def verificar_arquivo(nome_arquivo):
    with open(nome_arquivo, 'r', encoding='utf-8') as arquivo:
        for numero_linha, linha in enumerate(arquivo, start=1):
            if linha.strip() != "ABCD":
                print(f"Linha {numero_linha} diferente: {linha.strip()}")

# Exemplo de uso
nome_arquivo = "csvFiles/sef/samples_[2].csv"
verificar_arquivo(nome_arquivo)

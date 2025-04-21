import os
import sys
import subprocess
import shutil
import venv

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
VENV_DIR = os.path.join(PROJECT_DIR, '.venv')
PYTHON_EXECUTABLE = sys.executable
REQUIREMENTS_FILE = os.path.join(PROJECT_DIR, 'requirements.txt')
TARGET_SCRIPT = os.path.join(PROJECT_DIR, 'serialSave.py')

def print_section(title):
    print(f"\n=== {title} ===")

def remove_venv():
    if os.path.exists(VENV_DIR):
        print_section("Removendo ambiente virtual antigo")
        shutil.rmtree(VENV_DIR)
    else:
        print("[INFO] Nenhum venv antigo encontrado.")

def create_venv():
    print_section("Criando novo ambiente virtual")
    venv.create(VENV_DIR, with_pip=True)

def install_requirements():
    print_section("Instalando dependências do requirements.txt")
    pip_path = os.path.join(VENV_DIR, 'Scripts' if os.name == 'nt' else 'bin', 'pip')
    subprocess.check_call([pip_path, 'install', '-r', REQUIREMENTS_FILE])

def run_script():
    print_section(f"Executando {os.path.basename(TARGET_SCRIPT)}")
    python_path = os.path.join(VENV_DIR, 'Scripts' if os.name == 'nt' else 'bin', 'python')
    subprocess.check_call([python_path, TARGET_SCRIPT])

if __name__ == "__main__":
    print_section("BOOTSTRAP INICIADO")
    remove_venv()
    create_venv()
    install_requirements()
    run_script()

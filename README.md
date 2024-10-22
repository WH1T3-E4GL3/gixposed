# gixposed
Gixposed is a powerful command-line tool designed to search the commit history of Git repositories for sensitive information, such as API keys and access tokens. Its purpose is to help developers and security professionals quickly identify and remediate potential security vulnerabilities in their codebases.

# Installation

    wget https://github.com/WH1T3-E4GL3/gixposed/releases/download/v1.0.0/gixposed_1.0.0.deb
    sudo dpkg -i gixposed_1.0.0.deb

# Usage
    gixposed --s 'your_secret_to_check' --p '/root/your_repo_dir'
or
    gixposed

![Screenshot_2024-10-22_02_45_05](https://github.com/user-attachments/assets/724bfde9-5c4b-4cb6-a57e-640a1f5a68ec)

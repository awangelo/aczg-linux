### Task 1 - Inicializacao de Projetos

`aczg-init-project.sh` automatiza a criacao de novos projetos. O script recebe o nome do projeto e opcionalmente um caminho, cria o diretorio, gera um arquivo README.md inicial e configura um repositorio Git com o primeiro commit. O alias `aczgnew` utiliza esse script.

### Task 2 - Gerenciamento de Branches

`aczg-branch-init.sh` exibe o status do repositorio, cria uma nova branch seguindo o padrao `feat-<nome>` e lista todas as branches disponiveis. O alias `aczginit` utiliza esse script.

`aczg-branch-finish.sh` faz checkout na branch main, realiza o merge da branch de feature e a deleta localmente e remotamente. O alias `aczgfinish` utiliza esse script.

### Task 3 - Mini Pipeline de CI

`aczg-ci.sh` configura uma cron job para executar testes de projetos Gradle periodicamente. O script aceita uma expressao cron ou usa o padrao de 6 em 6 horas. Os resultados sao registrados em log e uma notificacao e enviada ao usuario.

`aczg-autocommit.sh` configura uma cron job para realizar commits diarios automaticos em um repositorio. Com horario padrao de 23:00.

Ambos os scripts funcionam em dois modos: `--setup` para configurar o cron job e `--run` para executar a acao.

### Task 4 - Visualizacao de Logs

Foi criado o alias `aczglog` que filtra e exibe os ultimos 50 registros de log do pipeline CI. Os logs sao identificados pela tag `[ACZG-CI]` e ficam armazenados em `~/.local/log/aczg/ci.log`.

### Task 5 - Instalador

Foi criado o script `install.sh` que configura o ambiente automaticamente. O instalador detecta o package manager (apt, dnf, pacman, emerge) e instala as dependencias. Em seguida copia os scripts para `~/.local/bin/aczg/`, configura os aliases no `~/.bashrc` e recarrega o shell.

__Observações__ 


Primeiramente obrigado pela oportunidade. 

Atualmente não faço uso de algumas tecnologias como o auto scalling e load balance da AWS, as aplicacoes que administro utilizam servidores fixoes, sendo assim esta parte provavelmente ficou a desejar.



Julgo que a forma mais correta seja a subida do serviço da forma solicitada seja por meio da ferramenta terraform,no entando como naodominoa a ferramenta coloquei apenas as intrucoes de subida de uma vm atraves dele,os arquivos sao main.tf e variables.tf


__Instruções__ 


O arquivo service.sh irá criar os recursos necessario subir uma vm,bem como o serviço solicitado e anexa-lo a um auto-scalling.

No inicio do arquivo ha algumas variaveis a serem preenchidas de acordo com seus requisitos (Chave e subnet).

Para que este script funcione deve ser instalado o aws cli (https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html), em seguida deve ser configurado com suas credenciais através do comando "aws configure"
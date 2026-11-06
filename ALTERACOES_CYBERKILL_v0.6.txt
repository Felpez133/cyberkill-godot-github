CYBERKILL v0.6 - ALTERACOES DE INTEGRACAO

Feito nesta revisão:
- Mantida a cena principal original (Menu.tscn) e o fluxo inicial existente.
- Start agora abre uma seleção de cinco mundos; apenas o Mundo 1 está liberado.
- Criado PlayerData como Autoload para persistência de arma, desbloqueios e checkpoint.
- Corrigida a conexão da área de ataque para detectar corpos (body_entered).
- Jogador: vida, invulnerabilidade visual, morte, reinício e menu.
- Jogador: movimento simultâneo ao disparo após coletar arma.
- Criados projétil e coleta de arma por E; coleta colocada na fase node_2d.
- Criado inimigo reutilizável com patrulha, detecção/perseguição, dano por contato, vida e reação ao dano; uma instância foi colocada na fase node_2d.
- Criada cena reutilizável de checkpoint (ainda precisa ser posicionada manualmente na fase).
- Pausa com continuar, reiniciar fase e voltar ao menu.
- Criada estrutura de pastas de áudio, sem gerar ou baixar sons.
- Preservados sprites e áudio originais.

Limitações / validação:
- Não foi possível executar o Godot nesta sessão; portanto não posso garantir teste real de F5 nem de colisões em runtime.
- O fundo Beta-City não foi reconstruído em camadas nesta revisão; os recursos originais foram preservados.
- O sistema de áudio novo tem estrutura de pastas, mas os efeitos ainda precisam ser ligados aos eventos e preenchidos com arquivos fornecidos por você.
- A arma é representada por projétil simples temporário; sprites finais de arma/projétil não foram inventados.
- O checkpoint reutilizável foi criado, mas deve ser arrastado para os locais desejados no editor.
- A persistência da arma é entre cenas enquanto a sessão do jogo permanece ativa; salvar em disco não foi implementado.
- Inimigo usa o sprite único existente de 32x32, sem animações inexistentes.
- Os mundos 2 a 5 permanecem bloqueados e sem fases associadas.

Para abrir:
1. Extraia a pasta do ZIP.
2. Na Godot 4.7, importe/abra project.godot.
3. Aguarde a importação dos recursos e pressione F6/F5 conforme necessário. O F5 usa Menu.tscn configurada no projeto.
4. Start -> Mundo 1.

Controles:
- A/D: mover
- W: pular
- Clique esquerdo: soco (antes da arma)
- Clique esquerdo: disparar (depois de pegar a arma)
- E: pegar arma / interagir com portal
- Esc: abrir pausa (continuar/reiniciar/menu)

Faça backup do projeto original antes de substituir sua pasta de trabalho.

CORREÇÃO EXTRA — WORLD 1 / PLAYER
- Corrigida a declaração de shot_timer e attack_timer em personagem.gd: havia uma sequência literal "\\n" no meio da linha, causando erro de análise do GDScript e impedindo o carregamento do jogador ao entrar no Mundo 1.
- As duas variáveis agora estão em linhas separadas.
- Nenhum sprite, cena, controle ou animação foi substituído nesta correção.
- Verificação realizada: busca por ocorrências restantes de "\\n" literal em scripts .gd e teste de integridade do ZIP.
- Limitação: execução dentro do editor Godot/F5 não disponível neste ambiente; validar abrindo o projeto no editor.

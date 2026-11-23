extends Area2D
## Gatilho de diálogo do tutorial. Posicione/duplique no editor e escolha a etapa no Inspector.
## Quem lê o "stage" é o tutorial.gd (nó "Triggers" da cena Tutorial.tscn).

@export_enum("Movimentação:0", "Caixa:1", "Wall Jump:2", "Arma:3", "Ataque e fim:4") var stage: int = 0

# Sobrevivência Sandbox 2D

Projeto Godot 4 (2D top-down sandbox de sobrevivência) criado para Android e PC.

## Requisitos
- Godot 4.3+ (recomendado 4.3/4.4 estável)
- Suporte a exportação Mobile/Android configurado no editor (templates de exportação)

## Como abrir
1. Abra o Godot 4.
2. Clique em **Import**.
3. Selecione a pasta do projeto (onde está `project.godot`).
4. Abra o projeto e execute a cena principal (`scenes/main/main.tscn`).

## Estrutura
- `scenes/` - Cenas do jogo (menus, mundo, jogador, inimigos, etc.)
- `scripts/` - Scripts GDScript por sistema
- `assets/` - Sprites, tilesets, UI, áudio
- `resources/` - Resources (.tres) de itens, receitas, inimigos, mundo
- `data/` - Dados de save/config
- `docs/` - Documentação e relatórios

## Controles (PC)
- WASD / Setas: mover (8 direções)
- Shift: correr
- E: interagir/coletar
- Espaço / Clique esquerdo: atacar/usar
- I / Tab: inventário
- B: modo construção
- Esc: pausar/menu

## Controles (Android)
- Joystick virtual e botões de ação na HUD (quando habilitados)

## Status
Projeto em desenvolvimento ativo. Consulte `docs/RELATORIO.md` para sistemas concluídos e pendências.

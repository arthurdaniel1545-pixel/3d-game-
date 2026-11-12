# Sobrevivência Sandbox 2D

Projeto Godot 4 (2D top-down sandbox de sobrevivência) com geração procedural, ciclo dia/noite, sobrevivência, crafting, construção, combate, inimigos/animais, loot e save.

## Requisitos
- Godot 4.3+ (recomendado 4.3/4.4 estável)
- Templates de exportação instalados para Android/desktop (para exportar)

## Como abrir
1. Abra o Godot 4.
2. Clique em **Import**.
3. Selecione a pasta do projeto (onde está `project.godot`).
4. Abra e execute a cena principal: `scenes/main/main.tscn`.

## Fluxo do jogo
- **Menu principal**: Novo Jogo, Continuar, Configurações, Sair.
- **Novo Jogo**: seleção de gênero (masculino/feminino) e personalização (nome, penteado, cores, roupa) antes da criação do mundo.
- **Mundo**: exploração, coleta, crafting, construção, combate e sobrevivência com save automático.

## Controles (PC)
- WASD / Setas: mover (8 direções)
- Shift: correr
- E: interagir/coletar (e descansar/dormir em abrigo quando apropriado)
- Espaço / Clique esquerdo: atacar/usar
- I / Tab: inventário
- B: modo construção (selecionar estrutura no painel e clicar para posicionar)
- Esc: pausar/menu (salva)

## Controles (Android)
- Controles virtuais na HUD (D-pad, atacar, interagir, correr) em telas touch.
- Interface adaptada para viewport com stretch `canvas_items`.

## Sistemas principais
- Personagem com spritesheets pixel art, movimento 8 direções, animações e personalização persistente.
- Sobrevivência: vida, fome, sede, energia, sono, ferimentos, doença, temperatura/abrigo.
- Mundo procedural (seed), biomas/regiões, POIs (vilas, cidades, hospital, mercado, base militar, cavernas), recursos e loot.
- Inimigos (zumbi, rápido, tanque, lobo) com detecção/perseguição, hordas noturnas e dificuldade progressiva.
- Inventário, equipamentos, crafting e construção com posicionamento/validação.
- Ciclo dia/noite, clima dinâmico e efeitos visuais.
- Save/load em `user://savegame.json` (personagem, stats, inventário, equipamentos, construções, mundo/tempo).

## Estrutura
- `scenes/` - Cenas (main, menus, mundo, jogador, inimigos, animais, objetos)
- `scripts/` - Scripts por sistema (managers, player, world, enemies, ui, combat, save)
- `assets/` - Sprites, tilesets, UI, itens, armas, ambiente
- `resources/` - Dados de itens, receitas, personagens
- `data/`, `addons/`, `docs/`

## Exportação
- `export_presets.cfg` inclui presets base para **Android** e **Windows Desktop**. Configure caminhos, keystore/assinatura Android e instale templates de exportação no Godot.

## Documentação
- [docs/RELATORIO.md](RELATORIO.md): auditoria, melhorias, sistemas, verificações e pendências.

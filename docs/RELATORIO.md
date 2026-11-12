# Relatório do Projeto - Sobrevivência Sandbox 2D (Godot 4)

## Resumo
Projeto Godot 4.3 (GDScript) criado no repositório com estrutura organizada, cenas, scripts e assets pixel art fornecidos/organizados. Verificações estáticas realizadas (integridade de referências `res://` em `project.godot`, cenas e preloads). **O Godot não foi executado diretamente neste ambiente**, portanto não há afirmação de teste em runtime/editor; apenas validações estáticas de arquivos e caminhos.

## Fases e sistemas implementados

### FASE 1 - Projeto e estrutura
- `project.godot` configurado (Godot 4.3, Mobile, viewport 1280x720, filtro de textura pixel art, input map, autoloads, camadas de física).
- Estrutura de pastas criada (`scenes/`, `scripts/`, `assets/`, `resources/`, `data/`, `addons/`, `docs/` e subpastas solicitadas).
- `icon.svg`, `.gitignore`, `docs/README.md`.

### FASE 2 - Personagem, movimento e câmera
- `scenes/player/player.tscn` + `scripts/player/player.gd`: movimento em 8 direções, caminhada/corrida, `Camera2D` com suavização.
- Animações com spritesheets reais (masculino/feminino) para idle/walk/run por direções disponíveis; mapeamento para 8 direções de input.
- Seleção de personagem antes do novo jogo: `scenes/menus/character_selection.tscn`, `scripts/player/character_selection.gd`, `scripts/player/character_customization.gd`.
- Personalização: gênero, nome, penteado, cor do cabelo/pele/olhos, roupa inicial, aleatorização e pré-visualização.
- Recursos base: `resources/characters/male_base.tres`, `resources/characters/female_base.tres`.
- Aparência/seleção integrada ao `GameManager` e persistida no save.

### FASE 3 - Mundo e geração procedural
- `scenes/world/world.tscn`, `scripts/world/world.gd`, `scripts/world/world_generator.gd`.
- Geração procedural com `FastNoiseLite` (seed por partida/save): terreno (água/areia/grama/terra) em `TileMapLayer`, distribuição de árvores, pedras e arbustos.
- Mundo explorável (mapa gerado amplo, sem limites artificiais rígidos além da área gerada).
- Recursos coletáveis: `scenes/objects/tree.tscn`, `rock.tscn`, `berry_bush.tscn` com sprites pixel art.

### FASE 4 - Sobrevivência, coleta e inventário
- Stats do jogador: vida, fome, sede, energia (`player.gd`) com consumo/regen e dano por fome/sede.
- Coleta/interação: árvores (madeira), pedras (pedra), arbustos (frutas + fibra), caça de animais (carne crua).
- Inventário: `scripts/managers/inventory_manager.gd` (slots, stack, add/remove/contagem, save/load).
- HUD com barras de vida/fome/sede/energia e painel de inventário visual.

### FASE 5 - Crafting e construção
- Crafting no HUD com receitas: tábuas, ferramentas (machado/picareta/faca), itens de construção (parede/piso/porta), fogueira, baú, bancada, bandagem, carne cozida.
- Dados de itens/receitas em `resources/items/items_data.json` e `resources/recipes/recipes_data.json`.
- Sistema de construção simplificado: modo construção (B), colocação de estruturas no mundo ao clicar/tocar quando há item construível no inventário; snap em grade 32px; persistência de construções no save.
- Bancadas/baú/fogueira representados como estruturas posicionáveis (funcionalidade de armazenamento avançado/estações específicas é básica).

### FASE 6 - Inimigos, animais e combate
- Base de inimigo com IA: `scripts/enemies/enemy_base.gd` (detecção, perseguição, ataque, dano, loot).
- Zumbi: `scenes/enemies/zombie.tscn`, `scripts/enemies/zombie.gd` usando spritesheets reais do pack PostApocalypse.
- Animal caçável com fuga: `scenes/animals/animal.tscn`, `scripts/enemies/animal.gd` (drop de carne crua).
- Spawn inicial e manutenção periódica de entidades no mundo.
- Combate: corpo a corpo (alcance/dano variável por ferramenta) e ataque à distância com projétil quando pistola equipada (`scenes/objects/projectile.tscn`, `scripts/combat/projectile.gd`). Equipar armas/ferramentas pelo inventário.

### FASE 7 - Ciclo de dia/noite e clima
- `scripts/managers/time_manager.gd`: tempo do mundo, dias, períodos (amanhecer/dia/entardecer/noite), fator de luz, clima dinâmico (limpo/nublado/chuva/tempestade) e temperatura.
- `CanvasModulate` no mundo ajusta iluminação conforme horário/clima.
- Sistema de temperatura básico no jogador: exposição noturna/frio sem abrigo próximo causa dano gradual (abrigos = construções próximas).

### FASE 8 - Interface e controles Android
- Menu principal: novo jogo, continuar, configurações, sair (`scenes/menus/main_menu.tscn`).
- Menu de configurações: volumes e autosave (`scenes/menus/settings_menu.tscn`).
- HUD: barras de vida/fome/sede/energia, relógio, dia, clima, botões de inventário/construção/menu (`scenes/menus/hud.tscn`).
- Inventário visual, lista de fabricação, menu de construção.
- Controles virtuais para Android (D-pad, atacar, interagir, correr) exibidos em dispositivos touch/mobile.
- Input map para PC e `emulate_touch_from_mouse` habilitado.

### FASE 9 - Salvamento e carregamento
- `scripts/managers/save_manager.gd`: save em `user://savegame.json`, carregamento, autosave periódico.
- Persiste: gênero/customização do personagem, stats e posição do jogador, inventário, dia/hora/clima/seed do mundo e construções colocadas.
- "Continuar" carrega save e restaura mundo/jogador.

### FASE 10 - Revisão e verificações estáticas
- Verificação automática de referências `res://` em `project.godot`, cenas `.tscn` e preloads `.gd`: **OK (sem caminhos ausentes)**.
- Compatibilidade alvo Godot 4.3/Mobile configurada em `project.godot`.
- `.gitignore` inclui `.godot/`, `.tmp_extract/`, etc.

## Assets utilizados
- Spritesheets de personagens (masculino/feminino) com animações (Idle/Walk/Death etc.) dos packs anexados.
- Tiles/props/recursos (árvores, pedras, arbustos), inimigos (zumbi), UI e itens dos packs PostApocalypse, Zombie Apocalypse, Pixel Crawler e packs de itens/armas anexados (organizados em `assets/`).
- Recursos gratuitos conforme pacotes fornecidos; licenças originais dos packs devem ser respeitadas conforme seus arquivos de licença/readme quando presentes nos arquivos fonte.

## Problemas conhecidos / pendências
- **Teste em runtime não executado**: Godot editor/engine não foi executado aqui; podem existir ajustes finos de cenas, colisões, animações ou UI ao abrir no editor.
- **Construção**: seleção de qual item construir é simplificada (coloca o primeiro construível disponível no inventário ao clicar no modo construção). Não há preview fantasma avançado nem rotação.
- **Persistência de recursos do mundo**: construções e estado global são salvos; árvores/pedras/arbustos e entidades são regenerados/recriados ao carregar (recursos coletados podem reaparecer).
- **Abrigos/temperatura**: modelo simplificado baseado em proximidade de construções e condições de noite/clima.
- **Equipamentos/inventário**: equipar arma/ferramenta por clique no slot (funcional) sem UI dedicada de slots de equipamento visuais completos.
- **Animais**: comportamento e representação funcional; sprite dedicado de animal pode ser aprimorado com assets específicos adicionais.
- **Áudio**: `AudioManager` presente, mas sem arquivos de áudio/música incluídos.
- **Tileset visual**: terreno base gerado proceduralmente com tiles programáticos; pode ser refinado com TileSet artístico dos packs no editor.
- **Exportação Android**: `project.godot` preparado para mobile, mas `export_presets.cfg` e templates de exportação devem ser configurados/instalados no Godot do usuário.

## Como validar no Godot
1. Importar a pasta do projeto no Godot 4.3+.
2. Abrir `scenes/main/main.tscn` (main scene).
3. Testar fluxo: Menu → Novo Jogo → Seleção/Personalização → Mundo.
4. Verificar movimento, coleta (E/ataque em recursos), inventário/crafting (I), construção (B), combate, ciclo dia/noite, salvar (menu/pausa) e continuar.

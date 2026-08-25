# Mining Layers (FS25)

[![Buy me fries](https://img.shields.io/badge/Buy%20me%20fries-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/fritteplayz)
[![Latest release](https://img.shields.io/github/v/release/FrittePlayz/FS25_MiningLayers?style=for-the-badge&color=2d8a4e)](https://github.com/FrittePlayz/FS25_MiningLayers/releases)
[![Idiomas](https://img.shields.io/badge/no--jogo-PT%20·%20EN%20·%20DE%20·%20FR%20·%20PL%20·%20IT-2d8a4e?style=for-the-badge)](#)

![Mining Layers — o material depende da profundidade da escavação, um add-on do TerraFarm](docs/images/00_header.jpg)

**Mineração de verdade no Farming Simulator 25 — escave através de camadas geológicas, ou faça a sua própria cascalheira no FS25.**
O material na caçamba depende de quanto você escava, não de um menu suspenso: primeiro a terra vegetal, depois o cascalho, depois o minério, rocha no fundo. Desde a 1.4.0 o minério é selecionável — mina de carvão, cascalheira ou pedreira de calcário, em qualquer mapa, sem editar o mapa. **O mod e o seu manual dentro do jogo existem por inteiro em português (pt e br)**, traduzidos por **Alicopower**.

🇬🇧 [English](README.md) · 🇩🇪 [Deutsch](README.de.md) · 🇫🇷 [Français](README.fr.md) · 🇵🇱 [Polski](README.pl.md) · 🇮🇹 [Italiano](README.it.md) — *página PT compacta; a documentação completa está na versão em inglês, o manual integral está no jogo, em português.*

---

## Tutorial em vídeo

[![Mining Layers 1.6 — o tutorial completo no YouTube](docs/images/14_video_tutorial.jpg)](https://www.youtube.com/watch?v=kR0h1_S8oHc)

29 minutos, da instalação ao Dozer: os slots de terreno, a altura de destino, o caso da água — e escavar sem área desenhada. Legendas em português, inglês, alemão, francês, polonês e italiano.

---

## Requisitos

- **[TerraFarm](https://github.com/scfmod/FS25_TerraFarm)** do scfmod — só no GitHub. Não renomeie a pasta dele: precisa continuar `FS25_0_TerraFarm` (ordem de carregamento).
- Pelo menos **uma máquina com configuração TerraFarm** (por exemplo o oficial `FS25_TerraFarmMachines`).
- **Só PC ou Mac** — é um script mod, os consoles não aceitam.

Add-on não oficial, sem vínculo com scfmod nem com a GIANTS. Nenhum arquivo do TerraFarm é incluído ou alterado.

## Instalação

1. Baixe o TerraFarm (link acima).
2. Baixe `FS25_MiningLayers.zip` nas [releases](https://github.com/FrittePlayz/FS25_MiningLayers/releases).
3. Coloque os dois ZIP — do jeito que estão, sem extrair — na pasta de mods:
   `Documentos\My Games\FarmingSimulator2025\mods\`
4. Ative OS DOIS mods na seleção de mods da sua partida.

## Novo na 1.6: você não precisa mais desenhar uma área

Até agora era preciso traçar um polígono do TerraFarm e atribuí-lo à máquina antes de qualquer coisa acontecer — e esse era o motivo número um pelo qual as pessoas achavam que o mod não funcionava.

Agora as camadas valem no mapa inteiro: na página de camadas, escolha o alvo **"Em todo lugar (sem área)"**, defina como *Mining Layers* e salve. Uma instalação nova já vem assim. **Uma instalação existente mantém o comportamento** até você mudar — uma atualização não deve mexer numa partida em andamento.

Uma área desenhada continua valendo onde você atribuir uma, e as duas saídas propositais continuam iguais: uma área desativada e uma área com material definido à mão não recebem camadas. Assim canteiros de obra e valas continuam limpos com o modo global ligado.

## A primeira cava, em um passo

Trace uma área do TerraFarm (polígono) em volta da futura cava e **deixe os campos de material vazios**. É só isso: escave em qualquer ponto dentro da área e o material vem da profundidade. Ou use o modo "Em todo lugar" acima e nem desenhe.

Ajustes e camadas: menu ESC → Mining Layers. Lá também está o manual completo, em português.

## Espessura das camadas

No mínimo 1,5 m por camada (o editor exige 1 m na de cima, 1,5 m abaixo) — mais fina que isso e a recolha dos montes quebra. **Com máquinas grandes como a PC 8000, 2 m por camada escava bem melhor.**

## As três causas mais comuns de "não recebo camadas"

1. **A máquina não tem área de entrada atribuída.** O TerraFarm liga as áreas à MÁQUINA, não ao lugar onde você está: ajustes da máquina (`Y` por padrão) → escolha a sua área como entrada. É o caso de suporte número um.
2. **Há um material definido na área** → a área trabalha de propósito como TerraFarm normal, sem camadas (modo canteiro de obra). Deixe os campos de material vazios.
3. **Você está escavando fora do polígono**, ou numa área do tipo caminho — caminhos nunca têm camadas.

## Duas coisas que surpreendem

**O material fica na caçamba mas não desce no chão.** Quantos materiais cabem no solo quem decide é o seu mapa, não o jogo: vale a largura de canal do height density map dele, segundo 2^n−1 — 63 vagas com 6 bits, 127 com 7, 255 com 8. O jogo base já ocupa 48. Quando as vagas acabam, os materiais registrados por último ficam de fora: funcionam na caçamba e vendem, mas não descarregam no terreno. O mod marca esses com `(!)`, e o relatório do mapa, na página de menu dele, diz em que situação você está.

**PAYDIRT, COAL e LIMESTONE não são materiais do jogo base** — precisam vir do seu mapa ou de um mod de mineração (mapas RGC como o Yukon Back Country têm).

O resto das perguntas — cascalheiras, carvão, camadas personalizadas, descarga, mover o display — está na [página em inglês](README.md), que é a completa.

## Teclas

**Teclado numérico /** mostra e esconde o display de profundidade enquanto uma máquina está ativa (era Numérico 5 até a 1.4.3). **Numérico ✱** liga o modo mover: clique no display para pegá-lo, clique de novo para soltar. Os dois podem ser remapeados em Opções → Controles → Mining Layers.

## Tradução

O português no jogo (pt e br) é uma contribuição do **Alicopower** ([Issue #7](https://github.com/FrittePlayz/FS25_MiningLayers/issues/7)) — obrigado! O italiano é do **marcols13** ([Discussion #1](https://github.com/FrittePlayz/FS25_MiningLayers/discussions/1)). Esta página foi traduzida por nós: correções de falantes nativos são muito bem-vindas, abra uma [issue](https://github.com/FrittePlayz/FS25_MiningLayers/issues) ou um pull request (os arquivos de idioma são XML simples em `l10n/`), e você entra nos créditos.

## Bugs e dúvidas

[GitHub Issues](https://github.com/FrittePlayz/FS25_MiningLayers/issues) — **anexe sempre o seu `log.txt`** (`Documentos/My Games/FarmingSimulator2025/log.txt`, copiado logo depois do problema). Ele traz a lista completa de mods e o erro de verdade — sem ele, normalmente não dá para ajudar.

## Patrocínio

Este mod é apoiado pelo [farmersingles.de](https://www.farmersingles.de), um site de relacionamento para quem é do campo. A plaquinha no canto de cada área não existe mais desde a 1.6.1.

*Mining Layers de Tommy Honold, Farmersingles.de. Um projeto [FrittePlayz](https://www.youtube.com/@FrittePlayz). Gratuito até aqui.*

## Licença

O Mining Layers é gratuito para baixar e jogar, mas **não é livre para redistribuição** — fsmodworks.com é o único local de download. Espelhos, forks e pacotes de mods não são permitidos; quase tudo o resto é, e o que não estiver coberto costuma ser autorizado se você perguntar antes. Condições completas em [LICENSE](LICENSE).

Esta aplicação iOS permite ao utilizador explorar raças de gatos usando dados da Cat API. O utilizador pode pesquisar raças, visualizar detalhes, marcar favoritos e ver uma média da expectativa de vida das suas raças favoritas.

-> Estratégias de Desenvolvimento
Arquitetura utilizada: MVVM (Model-View-ViewModel) com separação clara entre lógica, modelo de dados e interface.

Utilização de SwiftUI para a construção da interface com NavigationStack, List, AsyncImage, Searchable e @StateObject/@ObservedObject.

A lógica de favoritos foi estruturada com Set<String> para performance e simplicidade.

Para persistência local (funcionalidade offline), foi utilizado SwiftData, que armazena os IDs das raças favoritas mesmo após fechar a app.

-> Funcionalidades Implementadas
     Lista de raças com nome e imagem (quando disponível)
     Barra de pesquisa por nome
     Tela de detalhes com origem, temperamento, descrição e expectativa de vida
     Favoritar e desfavoritar raças
     Tela de favoritos com média da expectativa de vida
     Persistência local com SwiftData (funcionalidade offline dos favoritos)

-> Desafios Encontrados
Algumas raças da Cat API não possuem imagem, o que exigiu lógica de fallback para mostrar um ícone genérico.

Ao envolver todo o código com NavigationLink, o botão de favorito não funcionava e ia para a página da raça. A solução foi separar a navegação do botão, permitindo que cada um funcione de forma independente.

Inicialmente, os favoritos eram apenas em memória. A integração com SwiftData permitiu resolver a perda de favoritos entre sessões de forma nativa e eficiente.

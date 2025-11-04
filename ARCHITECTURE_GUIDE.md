# 🐱 CatApp - Arquitetura e Flow Completo

## 📋 **Visão Geral para Gestão**

A **CatApp** é uma aplicação iOS moderna que permite aos utilizadores navegar, pesquisar e marcar como favoritas diferentes raças de gatos. A app utiliza **The Composable Architecture (TCA)** para garantir código escalável, testável e manutenível.

---

## 🏗️ **Arquitetura da Aplicação**

### **🎯 Padrão Arquitetural: TCA (The Composable Architecture)**

```
┌─────────────────┐    Actions    ┌─────────────────┐    Effects    ┌─────────────────┐
│      Views      │──────────────▶│    Reducers     │──────────────▶│    Services     │
│  (Presentation) │               │  (Business      │               │   (External     │
│                 │               │   Logic)        │               │    World)       │
└─────────────────┘               └─────────────────┘               └─────────────────┘
         ▲                                 │                                 │
         │                                 ▼                                 │
         └────────────────────────── State Updates ◀─────────────────────────┘
```

**Benefícios da TCA:**
- ✅ **Unidirectional Data Flow**: Dados fluem sempre na mesma direção
- ✅ **Testabilidade**: Cada componente pode ser testado isoladamente
- ✅ **Debugging**: State changes são previsíveis e rastreáveis
- ✅ **Modularidade**: Features podem ser desenvolvidas independentemente

---

## 🌊 **Flow Completo da Aplicação**

### **1. 🚀 Inicialização da App**

```swift
CatAppApp.swift
├── Configura SwiftData Container
├── Modelos: [Favorite, CachedBreed, FavoriteBreedDetail]
└── Lança ContentView (MainView com TabBar)
```

**Função:** Ponto de entrada que configura a persistência local (SwiftData) e lança a interface principal.

### **2. 📱 Interface Principal (MainView)**

```swift
MainView.swift
├── TabView com 3 tabs:
│   ├── 🏠 Home (Lista de Raças)
│   ├── 🔍 Search (Pesquisa)
│   └── ❤️ Favorites (Favoritos)
├── Stores TCA independentes para cada feature
└── Navegação entre features
```

**Função:** Container principal que organiza as 3 funcionalidades principais da app.

---

## 🔄 **Flow Detalhado por Feature**

### **🏠 HOME - Lista de Raças**

#### **Componentes:**
1. **HomeListView.swift** - UI "burra" (apenas apresentação)
2. **HomePageReducer.swift** - Lógica de negócio (TCA Reducer)
3. **BreedsService.swift** - Acesso à API externa

#### **Flow:**
```
1. User abre a app
   ↓
2. HomeListView envia .onAppear
   ↓
3. HomePageReducer processa:
   - .loadCachedBreeds (carrega dados locais)
   - .refreshFavorites (carrega favoritos)
   - .fetchPage(0) (primeira página da API)
   ↓
4. BreedsService faz request à TheCatAPI
   ↓
5. Dados são guardados em BreedsCacheDatabaseService
   ↓
6. State é atualizado com breeds[]
   ↓
7. HomeListView re-renderiza com dados
```

#### **Paginação Inteligente:**
- **Infinite Scroll**: Carrega páginas automaticamente ao chegar ao fim
- **Cache First**: Mostra dados em cache imediatamente
- **Background Refresh**: Atualiza dados em segundo plano

### **🔍 SEARCH - Pesquisa de Raças**

#### **Componentes:**
1. **SearchView.swift** - Interface de pesquisa
2. **SearchReducer.swift** - Lógica de pesquisa
3. **SearchBar.swift** - Componente reutilizável

#### **Flow:**
```
1. User digita na SearchBar
   ↓
2. Debounce (evita requests excessivos)
   ↓
3. SearchReducer.searchTextChanged
   ↓
4. BreedsService.searchBreeds(query)
   ↓
5. API search endpoint
   ↓
6. Resultados apresentados em grid
```

### **❤️ FAVORITES - Gestão de Favoritos**

#### **Componentes:**
1. **FavoritesView.swift** - Lista de favoritos
2. **FavoritesReducer.swift** - Lógica de favoritos
3. **FavoritesService.swift** - Persistência de favoritos

#### **Flow:**
```
1. User marca/desmarca favorito
   ↓
2. .toggleFavorite action
   ↓
3. FavoritesService atualiza SwiftData
   ↓
4. Estado sincronizado em todas as views
   ↓
5. UI atualiza automaticamente
```

---

## 🗂️ **Estrutura de Pastas e Responsabilidades**

### **📁 Models (Modelos de Dados)**

```swift
├── CatBreed.swift           // Modelo principal da API (Codable)
├── CachedBreed.swift        // Modelo de cache (SwiftData)
├── Favorite.swift           // Modelo de favoritos (SwiftData)
├── FavoriteBreedDetail.swift // Detalhes de favoritos (SwiftData)
├── Endpoint.swift           // Definição type-safe de endpoints
└── APIConfig.swift          // Configuração da API
```

**Função dos Models:**
- **CatBreed**: Representa dados vindos da API (JSON ↔ Swift)
- **CachedBreed**: Persistência local para offline/performance
- **Favorite**: Rastreamento de favoritos do utilizador
- **Endpoint**: Centraliza configuração de URLs da API

### **📁 Services (Camada de Dados)**

```swift
├── NetworkService.swift            // HTTP requests genéricos
├── BreedsService.swift            // API específica de raças
├── FavoritesService.swift         // Gestão de favoritos
├── BreedsCacheDatabaseService.swift // Cache de raças
└── DatabaseService.swift          // SwiftData utilities
```

**Função dos Services:**
- **Abstraem complexidade** de rede e persistência
- **Fornecem interface limpa** para os Reducers
- **Centralizam lógica** de acesso a dados
- **Permitem testing** com mocks

### **📁 Reducers (Lógica de Negócio)**

```swift
├── HomePageReducer.swift      // Lógica da homepage
├── SearchReducer.swift        // Lógica de pesquisa
├── FavoritesReducer.swift     // Lógica de favoritos
└── BreedDetailReducer.swift   // Lógica de detalhes
```

**Função dos Reducers:**
- **Processam todas as actions** da UI
- **Atualizam o state** da aplicação
- **Orquestram side effects** (API calls, database)
- **Mantêm lógica de negócio** centralizada

### **📁 Views (Interface do Utilizador)**

```swift
├── MainView.swift              // TabBar principal
├── HomeListView.swift          // Grid de raças
├── SearchView.swift            // Interface de pesquisa
├── FavoritesView.swift         // Lista de favoritos
├── BreedDetailView.swift       // Detalhes de uma raça
└── Components/
    ├── BreedSquareTile.swift   // Card de raça
    ├── CatImageView.swift      // Imagem com cache
    └── SearchBar.swift         // Barra de pesquisa
```

**Função das Views:**
- **Apresentação pura** - sem lógica de negócio
- **Recebem state** dos Reducers
- **Enviam actions** para Reducers
- **Componentes reutilizáveis**

### **📁 Constants (Configuração)**

```swift
├── UIStrings.swift         // Todas as strings da UI
├── UIDimensions.swift      // Tamanhos e medidas
├── UILayout.swift          // Espaçamentos e layouts
├── UIConfig.swift          // Configurações de UI
└── APIConstants.swift      // Configurações de rede
```

**Função das Constants:**
- **Centralizam configuração** 
- **Evitam magic numbers/strings**
- **Facilitam manutenção**
- **Suportam localização**

---

## 🌐 **Integração com API Externa**

### **The Cat API Integration**

**Base URL:** `https://api.thecatapi.com/v1/`

**Endpoints Utilizados:**
```swift
GET /breeds?page=0&limit=20           // Lista paginada de raças
GET /breeds/search?q=bengal           // Pesquisa de raças
GET /images/search?breed_ids=beng     // Imagens de uma raça específica
```

**Fluxo de Request:**
```
1. Endpoint.swift define URLs type-safe
   ↓
2. APIConfig.swift configura headers/auth
   ↓
3. NetworkService.swift executa HTTP request
   ↓
4. BreedsService.swift processa response
   ↓
5. JSON é convertido para CatBreed models
   ↓
6. Dados são cacheados localmente
   ↓
7. State é atualizado via Reducer
```

### **🔐 Autenticação e Segurança**

```swift
// API Key é injetada via Info.plist
ConfigDecoder.swift → secrets.catApiKey
                  ↓
APIConfig.swift → static var apiKey
                  ↓
Endpoint.swift → request() adiciona header
```

**Benefícios:**
- ✅ **API Key não fica hardcoded** no código
- ✅ **Diferentes keys** para dev/staging/prod
- ✅ **Segurança** via Info.plist

---

## 💾 **Estratégia de Persistência**

### **SwiftData para Persistência Local**

```swift
📦 Local Database (SwiftData)
├── CachedBreed (cache de raças da API)
├── Favorite (IDs de favoritos)
└── FavoriteBreedDetail (detalhes completos de favoritos)
```

**Vantagens da Estratégia:**
- ✅ **Offline First**: App funciona sem internet
- ✅ **Performance**: Dados locais carregam instantaneamente  
- ✅ **Sync Inteligente**: Atualiza em background
- ✅ **Favoritos Persistem**: Não se perdem entre sessões

### **Cache Strategy**

```
🔄 Cache Flow:
1. Request da API
2. Save local (BreedsCacheDatabaseService)
3. Load da cache (instantâneo)
4. Background refresh (atualização silenciosa)
```

---

## 🧪 **Testing Strategy**

### **Tipos de Tests Implementados:**

```swift
📁 CatAppTests1/
├── CatBreedsViewModelTests.swift     // Tests de ViewModels
├── BreedDetailViewModelTests.swift   // Tests de detalhes
├── MockBreedsRepository.swift        // Mocks para testing
├── MockNetworkService.swift          // Mock da rede
└── LifespanTest.swift               // Tests de cálculos
```

**Benefícios dos Tests:**
- ✅ **Confidence** em mudanças de código
- ✅ **Regression Prevention** 
- ✅ **Documentation** via tests
- ✅ **Mocks** permitem testing isolado

---

## 🎯 **Benefícios da Arquitetura Escolhida**

### **Para o Negócio:**
- ⚡ **Performance**: Cache inteligente + offline support
- 🚀 **Escalabilidade**: TCA permite crescimento da app
- 🐛 **Qualidade**: Menos bugs devido à arquitetura robusta
- 🔄 **Manutenibilidade**: Código bem organizado = menos tempo de development

### **Para a Equipa de Desenvolvimento:**
- 🧩 **Modularidade**: Features independentes
- 🧪 **Testabilidade**: Cada componente é testável
- 📚 **Previsibilidade**: State management claro
- 🔍 **Debugging**: Fluxo de dados transparente

### **Para o Utilizador:**
- ⚡ **Velocidade**: App responde instantaneamente
- 📱 **Offline**: Funciona sem internet
- 🔄 **Sync**: Dados sempre atualizados
- 💾 **Persistência**: Favoritos não se perdem

---

## 🚀 **Próximos Passos / Roadmap**

### **Funcionalidades Futuras:**
1. **Push Notifications** para novas raças
2. **Sharing** de raças favoritas
3. **User Profiles** e sincronização cloud
4. **Advanced Filters** (temperamento, origem, etc.)
5. **Breed Comparison** lado a lado

### **Melhorias Técnicas:**
1. **CI/CD Pipeline** com testing automático
2. **Analytics** para tracking de utilização  
3. **Crash Reporting** para monitoring
4. **Performance Monitoring** 
5. **A/B Testing** framework

---

## 📊 **Métricas de Sucesso**

- **Performance**: App load < 2s
- **Offline**: 100% funcional sem internet
- **Crash Rate**: < 0.1%
- **User Retention**: Tracking via analytics
- **Test Coverage**: > 80%

---

*Esta arquitetura garante que a CatApp seja robusta, escalável e proporcione uma excelente experiência ao utilizador, enquanto mantém o código limpo e manutenível para a equipa de desenvolvimento.*
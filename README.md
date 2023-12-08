# ShopAlgorithms

## Opis

Biblioteka `ShopAlgorithms` zawiera implementacje algorytmów rozwiązujących problem szeregowania zadań na maszynach (ang. *Job Shop Scheduling Problem*). W bibliotece zaimplementowane są następujące algorytmy:
- algorytm dla problemu szeregowania zadań na dwóch maszynach,
- algorytm dla problemu szeregowania dla dwóch zadań,
- algorytm `Branch and Bound` dla ogólnego problemu szeregowania zadań na maszynach oraz
- algorytm `Shifting Bottleneck` dla ogólnego problemu szeregowania zadań na maszynach.

## Instalacja

Biblioteka wymaga zainstalowania języka Julia w wersji 1.9.0 lub nowszej.

Istnieją dwie opcje instalacji biblioteki `ShopAlgorithms`. Pierwsza z nich to instalacja bezpośrednio z repozytorium GitHub:
```julia
import Pkg
Pkg.add("https://github.com/mteplicki/JobShopAlgorithms")
using ShopAlgorithms
```

Druga opcja to zbudowanie biblioteki z plików źródłowych. W tym celu należy pobrać repozytorium i przejść do głównego katalogu projektu. Następnie należy uruchomić REPL Julii i wykonać następujące polecenia:
```bash
julia --project
```
W REPLu należy zaimportować pakiet `Pkg` i wykonać następujące polecenia:
```julia
import Pkg
Pkg.instantiate()
using ShopAlgorithms
```

## Użycie

```julia
using ShopAlgorithms
instance = InstanceLoaders.random_instance_generator(5, 5)
result = Algorithms.branchandbound_carlier(instance)
println(result)
```
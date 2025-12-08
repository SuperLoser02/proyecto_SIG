from typing import Dict, List, Tuple, Set
import heapq

# Colores ANSI por línea
LINE_COLORS = {
    'L1': '\033[91m',  # rojo
    'L2': '\033[96m',  # celeste
    'L3': '\033[90m',  # gris/negro
    'L4': '\033[93m',  # naranja/amarillo
    'L5': '\033[92m',  # verde
    'L6': '\033[33m',  # amarillo oscuro
    '?': '\033[0m',    # sin color
}
RESET = '\033[0m'

# Modelo de grafo: nodo -> lista de (destino, peso, línea)
Graph = Dict[str, List[Tuple[str, int, str]]]

def build_sample_graph() -> Graph:
    g: Graph = {
        'A': [('B', 5, 'L1'), ('D', 5, 'L2'), ('D', 5, 'L6'), ('E', 5, 'L3'), ('E', 5, 'L5')],
        'B': [('C', 6, 'L1'), ('A', 5, 'L1')],
        'C': [('F', 5, 'L1'), ('B', 5, 'L1')],
        'D': [('F', 6, 'L2'), ('F', 6, 'L4')],
        'E': [('G', 4, 'L3'), ('F', 8, 'L5')],
        'F': [('H', 6, 'L2'), ('I', 3, 'L3'), ('I', 3, 'L4'), ('C', 5, 'L1')],
        'G': [('H', 2, 'L3')],
        'H': [('J', 3, 'L3'), ('F', 3, 'L2')],
        'I': [('F', 3, 'L3'), ('F', 3, 'L4')],
        'J': [],
    }
    return g

def dijkstra(graph: Graph, start: str) -> Dict[str, int]:
    dist = {node: float('inf') for node in graph}
    dist[start] = 0
    pq = [(0, start)]
    while pq:
        d, u = heapq.heappop(pq)
        if d > dist[u]:
            continue
        for v, w, _line in graph[u]:
            nd = d + w
            if nd < dist[v]:
                dist[v] = nd
                heapq.heappush(pq, (nd, v))
    return dist

def dfs_all_simple_paths(graph: Graph, u: str, target: str, visited: Set[str], path: List[str],
                         acc_weight: int, acc_lines: List[str],
                         results: List[Tuple[List[str], int, int, List[str]]],
                         max_depth=10):
    if len(path) > max_depth:
        return
    if u == target:
        transfers = count_transfers(acc_lines)
        results.append((path.copy(), acc_weight, transfers, acc_lines.copy()))
        return
    for v, w, line in graph.get(u, []):
        if v in visited:
            continue
        visited.add(v)
        path.append(v)
        acc_lines.append(line)
        dfs_all_simple_paths(graph, v, target, visited, path, acc_weight + w, acc_lines, results, max_depth)
        acc_lines.pop()
        path.pop()
        visited.remove(v)

def count_transfers(lines: List[str]) -> int:
    if not lines:
        return 0
    transfers = 0
    current = lines[0]
    for l in lines[1:]:
        if l != current:
            transfers += 1
            current = l
    return transfers

def find_all_paths(graph: Graph, start: str, end: str, max_depth=10) -> List[Tuple[List[str], int, int, List[str]]]:
    results: List[Tuple[List[str], int, int, List[str]]] = []
    if start not in graph or end not in graph:
        return results
    dfs_all_simple_paths(graph, start, end, {start}, [start], 0, [], results, max_depth)
    return results

def format_path(p: List[str]) -> str:
    return ' -> '.join(p)

def format_path_with_lines(path: List[str], lines: List[str]) -> str:
    return ' -> '.join(
        f"{path[i]}({LINE_COLORS.get(lines[i-1], '')}{lines[i-1]}{RESET})"
        for i in range(1, len(path))
    )

def main():
    graph = build_sample_graph()

    # Cambia aquí los valores de origen y destino:
    ORIGEN = "F"
    DESTINO = "D"

    print("*** RUTA ÓPTIMA - DEMO ***")
    print("Nodos disponibles:", ', '.join(sorted(graph.keys())))
    print(f"Buscando caminos desde {ORIGEN} hasta {DESTINO}...\n")

    paths = find_all_paths(graph, ORIGEN, DESTINO, max_depth=10)
    if not paths:
        print(f"No se encontraron caminos desde {ORIGEN} hasta {DESTINO}.")
        return

    # Ordenar por costo y luego por menos trasbordos
    paths_sorted = sorted(paths, key=lambda x: (x[1], x[2]))

    print(f"Caminos encontrados de {ORIGEN} a {DESTINO} (ordenados por costo):")
    for i, (p, cost, transfers, lines) in enumerate(paths_sorted, start=1):
        path_str = format_path(p)
        line_str = format_path_with_lines(p, lines)
        print(f"{i}) {path_str}  |  líneas: {line_str}  |  costo={cost}  |  trasbordos={transfers}")

    # Mostrar ruta óptima con líneas
    best_index = 1
    best_path, best_cost, best_transfers, best_lines = paths_sorted[0]
    best_path_str = format_path(best_path)
    best_line_str = format_path_with_lines(best_path, best_lines)
    print(f"\nRuta óptima: opción {best_index} -> {best_path_str}  |  líneas: {best_line_str}  |  costo={best_cost}  |  trasbordos={best_transfers}")

if __name__ == '__main__':
    main()

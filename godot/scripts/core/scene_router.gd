extends Node

signal route_changed(route)

var current_route := "hub"

func go(route: String) -> void:
    current_route = route
    AppState.mark_route(route)
    route_changed.emit(route)

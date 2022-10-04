tool
class_name NodeGraphNode
extends Container

signal selected
signal deselected

signal port_added(port_index)
signal port_updated(port_index)
signal port_removed(port_index)

const PORT_SIZE = 5
const CORNER_RADIUS = 10

class Port extends Resource:
	var node: NodeGraphNode
	
	export(int) var type setget _set_type
	export(Color) var color = Color.white setget _set_color
	export(bool) var enabled = true setget _set_enabled
	
	export(float) var hanchor setget _set_hanchor
	export(float) var vanchor setget _set_vanchor
	
	export(Vector2) var offset setget _set_offset

	var updated_signal_pending: bool = false
	var position_dirty: bool = false
	var position: Vector2

	func _init(node: NodeGraphNode):
		self.node = node
	
	func get_position() -> Vector2:
		if position_dirty:
			var rect_size = node.rect_size
			position = offset + Vector2(hanchor * rect_size.x, vanchor * rect_size.y)
			position_dirty = false
		return position
	
	func _queue_port_updated() -> void:
		if updated_signal_pending:
			return
		updated_signal_pending = true
		call_deferred("_emit_port_updated")
	
	func _emit_port_updated() -> void:
		node.emit_signal("port_updated", node._ports.find(self))
		updated_signal_pending = false

	func _set_type(value: int) -> void:
		if type == value:
			return
		
		type = value
		_queue_port_updated()
		node.update()

	func _set_color(value: Color) -> void:
		if color == value:
			return
		
		color = value
		_queue_port_updated()
		node.update()

	func _set_enabled(value: bool) -> void:
		if enabled == value:
			return
		
		enabled = value
		_queue_port_updated()
		node.update()

	func _set_hanchor(value: float) -> void:
		if hanchor == value:
			return
		
		hanchor = value
		position_dirty = true
		_queue_port_updated()
		node.update()

	func _set_vanchor(value: float) -> void:
		if vanchor == value:
			return
		
		vanchor = value
		position_dirty = true
		_queue_port_updated()
		node.update()

	func _set_offset(value: Vector2) -> void:
		if offset == value:
			return
		
		offset = value
		position_dirty = true
		_queue_port_updated()
		node.update()

export(Vector2) var node_position: Vector2 setget set_node_position, get_node_position

export(bool) var selected: bool setget set_selected
export(int) var port_count: int setget set_port_count, get_port_count

var _top_layer: CanvasItem
var _ports: Array = []

func _init():
	_top_layer = Control.new()
	_top_layer.connect("draw", self, "_top_layer_draw")
	_top_layer.set_anchors_preset(Control.PRESET_WIDE)
	_top_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top_layer)

func _ready() -> void:
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.7, 0.7, 0.7, 0.5)
	stylebox.set_corner_radius_all(CORNER_RADIUS)
	add_stylebox_override("body", stylebox)
	
	var border_normal = StyleBoxFlat.new()
	border_normal.draw_center = false
	border_normal.set_corner_radius_all(CORNER_RADIUS)
	border_normal.border_color = Color.black
	border_normal.set_border_width_all(1.0)
	add_stylebox_override("border_normal", border_normal)
	
	var border_selected = StyleBoxFlat.new()
	border_selected.draw_center = false
	border_selected.set_corner_radius_all(CORNER_RADIUS)
	border_selected.border_color = Color.yellow
	border_selected.set_border_width_all(1.0)
	add_stylebox_override("border_selected", border_selected)
	
	mouse_filter = Control.MOUSE_FILTER_PASS
	connect("item_rect_changed", self, "_on_rect_changed")

func get_node_position() -> Vector2:
	if get_parent():
		return rect_position - get_parent().scroll_offset
	return rect_position

func set_node_position(new_position: Vector2) -> void:
	var offset: Vector2 = Vector2()
	if get_parent():
		offset = get_parent().scroll_offset
	rect_position = new_position + offset

func _on_rect_changed() -> void:
	for port in _ports:
		port.position_dirty = true

func _get_property_list() -> Array:
	var property_list = []
	for i in _ports.size():
		var port = _ports[i]
		property_list.append_array(_get_port_properties(port, "ports/" + str(i) + "/"))
	
	return property_list

func _get_port_properties(port: Port, prefix: String) -> Array:
	var properties = []
	properties.push_back({"name": prefix + "type", "type": TYPE_INT})
	properties.push_back({"name": prefix + "color", "type": TYPE_COLOR})
	properties.push_back({"name": prefix + "enabled", "type": TYPE_BOOL})
	properties.push_back({"name": prefix + "horizontal_anchor", "type": TYPE_REAL, "hint": PROPERTY_HINT_RANGE, "hint_string": "0,1"})
	properties.push_back({"name": prefix + "vertical_anchor", "type": TYPE_REAL, "hint": PROPERTY_HINT_RANGE, "hint_string": "0,1"})
	properties.push_back({"name": prefix + "offset", "type": TYPE_VECTOR2})
	
	return properties

func _get(path: String):
	if path.begins_with("ports/"):
		return _get_port_property(path.substr(6))
	return null

func _set(path: String, value) -> bool:
	if path.begins_with("ports/"):
		return _set_port_property(path.substr(6), value)
	return false

func _get_port_property(path: String):
	var parts = path.split("/")
	var index = int(parts[0])
	if index < 0 or index >= _ports.size():
		return false
	if parts.size() != 2:
		return false
	match parts[1]:
		"type":
			return _ports[index].type
		"color":
			return _ports[index].color
		"enabled":
			return _ports[index].enabled
		"horizontal_anchor":
			return _ports[index].hanchor
		"vertical_anchor":
			return _ports[index].vanchor
		"offset":
			return _ports[index].offset
		_:
			return null

func _set_port_property(path: String, value) -> bool:
	var parts = path.split("/")
	var index = int(parts[0])
	if index < 0 or index >= _ports.size():
		return false
	if parts.size() != 2:
		return false
	match parts[1]:
		"type":
			_ports[index].type = value
		"color":
			_ports[index].color = value
		"enabled":
			_ports[index].enabled = value
		"horizontal_anchor":
			_ports[index].hanchor = value
			_ports[index].position_dirty = true
		"vertical_anchor":
			_ports[index].vanchor = value
			_ports[index].position_dirty = true
		"offset":
			_ports[index].offset = value
			_ports[index].position_dirty = true
		_:
			return false
	update()
	return true

func get_port_count() -> int:
	return _ports.size()

func set_port_count(value: int) -> void:
	if value == _ports.size():
		return
	
	for i in range(value, _ports.size()):
		emit_signal("port_removed", i)
	
	_ports.resize(value)
	
	for i in _ports.size():
		if !_ports[i]:
			var port = Port.new(self)
			port.updated_signal_pending = false
			_ports[i] = port
			emit_signal("port_added", i)
	
	property_list_changed_notify()
	update()

func get_port(index: int) -> Port:
	return _ports[index]

func set_selected(value: bool) -> void:
	if selected == value:
		return
	
	selected = value
	if selected:
		emit_signal("selected")
	else:
		emit_signal("deselected")
	
	_top_layer.update()
	update()

func _draw() -> void:
	_top_layer.raise()
	
	var stylebox = get_stylebox("body")
	draw_style_box(stylebox, Rect2(Vector2(), get_size()))

func _top_layer_draw() -> void:
	var stylebox = get_stylebox("border_normal")
	if selected:
		stylebox = get_stylebox("border_selected")
	
	_top_layer.draw_style_box(stylebox, Rect2(Vector2(), get_size()))
	
	for i in _ports.size():
		_draw_port(_ports[i])

func _draw_port(port: Port) -> void:
	var position = port.get_position()
	_top_layer.draw_circle(position, PORT_SIZE, port.color)
	_top_layer.draw_arc(position, PORT_SIZE, 0, TAU, 32, Color.black, 1, true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		for port in _ports:
			port.position_dirty = true

func get_port_position(index: int) -> Vector2:
	if index < 0 or index >= _ports.size():
		return Vector2()
	
	return rect_position + _ports[index].get_position()

func get_port_control_point(index: int) -> Vector2:
	if index < 0 or index >= _ports.size():
		return Vector2()
	
	var position = _ports[index].get_position()
	
	var control = Vector2(-20, 0)
	var best_distance = abs(position.x)
	
	if abs(rect_size.x - position.x) < best_distance:
		best_distance = abs(rect_size.x - position.x)
		control = Vector2(20, 0)
	if abs(position.y) < best_distance:
		best_distance = abs(position.y)
		control = Vector2(0, -20)
	if abs(rect_size.y - position.y) < best_distance:
		best_distance = abs(rect_size.y - position.y)
		control = Vector2(0, 20)
	return control
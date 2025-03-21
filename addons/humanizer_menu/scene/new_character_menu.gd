extends Control

var shapekey_opposites = [["decr","incr"], ["down","up"],   ["in","out"],   ["backward","forward"],  ["concave","convex"],  ["compress","uncompress"], ["square","round"], ["pointed","triangle"]]
var camera_zoom = 0
var zoom_in_offset = 0
var zoom_out_offset = 1.5
var zoom_in_size = .25
var zoom_out_size = 3
var zoom_mid_ratio = 0
var zoom_mid_offset = 0
var humanizer := Live_Humanizer.new()

func _ready():
	var config = HumanConfig.new()
	config.targets['gender'] = 0.0
	config.init_macros()
	config.eye_color = Color.GREEN
	config.hair_color = Color.PURPLE
	config.eyebrow_color = Color("550055")
	config.rig = ProjectSettings.get_setting( "addons/humanizer/default_skeleton")
	var body = HumanizerEquipment.new("Body-Default","young_caucasian_male")
	var overlay = HumanizerOverlay.new()
	overlay.resource_name = "skin_young"
	body.material_config.add_overlay(overlay)
	config.add_equipment(body)
	config.add_equipment(HumanizerEquipment.new("Pants-SkinnyJeans"))
	config.add_equipment(HumanizerEquipment.new("Shirt-MakeHumanTShirt"))
	config.add_equipment(HumanizerEquipment.new("Shoes-02"))
	config.add_equipment(HumanizerEquipment.new("RightEye-LowPolyEyeball"))
	config.add_equipment(HumanizerEquipment.new("LeftEye-LowPolyEyeball"))
	config.add_equipment(HumanizerEquipment.new("Hair-Ponytail01_Rigged"))
	config.add_equipment(HumanizerEquipment.new("RightEyebrow-002"))
	config.add_equipment(HumanizerEquipment.new("LeftEyebrow-002"))
	config.add_equipment(HumanizerEquipment.new("RightEyelash"))
	config.add_equipment(HumanizerEquipment.new("LeftEyelash"))
	humanizer.load_config_async(config)
	init_character()
	build_menu()

	get_camera_min_max()
	%Camera3D.position.y = 0
	%Camera3D.position.x = 0
	%Camera3D.position.z = 1
	%Camera3D.v_offset = zoom_out_offset
	%Camera3D.size = zoom_out_size
	%zoom_slider.value = .4
	#_on_zoom_slider_value_changed(%zoom_slider.value)

func init_character():
	var char = humanizer.get_CharacterBody3D(false) ## can bake character here by setting argument to true
	%Platform.add_child(char)
	char.global_position = Vector3.ZERO
	HumanizerUtils.set_node_owner(char,self)
	char.camera = %Camera3D

func update_character():
	get_camera_min_max()
	
func get_camera_min_max():
	var middle_eyes = humanizer.helper_vertex[5063]
	zoom_in_offset = middle_eyes.y 
	var top_head = humanizer.helper_vertex[5063]
	zoom_mid_ratio = top_head.y / (zoom_out_size - zoom_in_size)
	zoom_mid_offset = top_head.y / 2

#needed or second save will have wrong skeleton and corrupted mesh
#delete folder before saving!
func delete_directory(path):
	for dir_name in OSPath.get_dirs(path):
		delete_directory(dir_name)
	for file_name in OSPath.get_files(path):
		DirAccess.remove_absolute(file_name)
	DirAccess.remove_absolute(path)
	
func build_menu():
	
	var shapekey_categories = HumanizerTargetService.get_shapekey_categories()
	for category_name in shapekey_categories:
		var category_keys = {}
		for shapekey_name in shapekey_categories[category_name]:
			if not shapekey_name.begins_with("asym-"):
				var base_key_name = shapekey_name
				if shapekey_name.begins_with("l-") or shapekey_name.begins_with("r-"):
					base_key_name = base_key_name.substr(2).strip_edges()
				if base_key_name not in category_keys:
					category_keys[base_key_name] = []
				category_keys[base_key_name].append(shapekey_name)
			
		shapekey_categories[category_name] = category_keys
		#print(base_key_name.get_slice("-",base_key_name.get_slice_count("-")-1))
	
	shapekey_categories.Macro.erase("gender")
	var category_keys = shapekey_categories["Macro"]	
	for key_name in category_keys:
		var slider = load("res://addons/humanizer_menu/scene/shapekey_slider.tscn").instantiate()
		slider.label_name = key_name
		slider.shapekeys = category_keys[key_name]
		slider.set_value(50)
		slider.change_shapekeys.connect(set_shapekeys)
		%Macro_Sliders.add_child(slider)
		
	category_keys = shapekey_categories["Race"]	
	for key_name in category_keys:
		var slider = load("res://addons/humanizer_menu/scene/shapekey_slider.tscn").instantiate()
		slider.label_name = key_name
		slider.shapekeys = category_keys[key_name]
		slider.set_value(33)
		slider.change_shapekeys.connect(set_shapekeys)
		%Race_Sliders.add_child(slider)
	
	shapekey_categories.erase("Macro")
	shapekey_categories.erase("Race")
	shapekey_categories.erase("Misc") #verify this is still empty
	
	for hair_type : HumanizerEquipmentType in HumanizerRegistry.filter_equipment({"slot"="hair"}):
		var hair_name = hair_type.display_name
		var icon = load("res://addons/humanizer_menu/assets/thumbnails/hair/" + hair_type.resource_name.to_lower() + ".png")
		add_option_meta(hair_name,hair_type.resource_name,%HairTypeSelect,icon)

	for eyebrow_type : HumanizerEquipmentType in HumanizerRegistry.filter_equipment({"slot"="righteyebrow"}):
		var eyebrow_id = eyebrow_type.resource_name
		var id = eyebrow_id.get_slice("-",1)
		#print(id)
		var icon = load("res://addons/humanizer_menu/assets/thumbnails/eyebrow"+id+".png")
		add_option_meta("",eyebrow_id,%EyebrowTypeSelect,icon)

	for i in 4:
		if i == 2:
			continue #skip the third, its the same as the second
		var id:String = str(0)+str(i+1)
		var icon = load("res://addons/humanizer_menu/assets/thumbnails/eyelashes"+id+".png")
		%EyelashTypeSelect.add_icon_item(icon,"")
	
	for slot in ProjectSettings.get_setting("addons/humanizer/slots")["Clothing"]:
		var slot_name = ProjectSettings.get_setting("addons/humanizer/slots")["Clothing"][slot]
		add_label(slot_name,%Equipment)
		var select_equip = OptionButton.new()
		%Equipment.add_child(select_equip)
		add_option_meta(" -- None -- ",slot,select_equip)
		for equip_type in HumanizerRegistry.filter_equipment({slot=slot}):
			var equip_id = equip_type.resource_name
			for texture_id in equip_type.textures:
				var texture_name = equip_type.textures[texture_id].resource_name
				add_option_meta(equip_type.display_name + " - " + texture_name,[equip_id,texture_id],select_equip)
		select_equip.item_selected.connect(equipment_selected.bind(select_equip))	
		
	for category_name in shapekey_categories:
		add_label(" --- " + category_name + " --- ",%Details)
		category_keys = shapekey_categories[category_name]
		for key_name:String in category_keys:
			var has_opposite = false
			for opposite_pair in shapekey_opposites:
				if key_name.ends_with("-" + opposite_pair[0]):
					var base_name = key_name.substr(0,key_name.length()-opposite_pair[0].length())
					var up_name = base_name + opposite_pair[1]
					if up_name in category_keys:
						var slider = load("res://addons/humanizer_menu/scene/double_shapekey_slider.tscn").instantiate()
						slider.label_name = key_name + " / " + opposite_pair[1]
						slider.shapekeys = category_keys[up_name]
						slider.shapekeys_down = category_keys[key_name]
						slider.change_shapekeys.connect(set_shapekeys)
						%Details.add_child(slider)
						has_opposite = true
					else:
						print("matching opposite not found " + key_name)
					continue
				elif key_name.ends_with(opposite_pair[1]):
					var base_name = key_name.substr(0,key_name.length()-opposite_pair[1].length())
					if (base_name + opposite_pair[0]) in category_keys:
						#key has already been matched
						has_opposite = true
					else:
						print("matching opposite not found " + key_name)
					continue
			if not has_opposite:
				var slider = load("res://addons/humanizer_menu/scene/shapekey_slider.tscn").instantiate()
				slider.label_name = key_name
				slider.shapekeys = category_keys[key_name]
				slider.change_shapekeys.connect(set_shapekeys)
				%Details.add_child(slider)

func update_skin_texture():
	var body_material:HumanizerMaterial = humanizer.human_config.equipment["Body-Default"].material_config
	var ratios = get_skin_color_ratios()
	for idx in ratios.size():
		var ratio = ratios[idx]
		var overlay:HumanizerOverlay = body_material.overlays[idx]
		overlay.color = %SkinColorPicker.color
		overlay.color.a = ratio[1]
		var mat :StandardMaterial3D = HumanizerRegistry.equipment["Body-Default"].textures[ratio[0]]
		overlay.albedo_texture_path = HumanizerOverlay.strip_texture_path(mat.albedo_texture.resource_path)
	humanizer.update_material("Body-Default")
	#skin_shader.set_shader_parameter("skin_ratios",ratios)
	#print(ratios)

func get_skin_color_ratios():
	var ratios = []
	var age_ranges = [0.0,.5,1]
	var gender = "female"
	if get_gender():
		gender = "male"
	var age = humanizer.human_config.targets["age"]
	if age < age_ranges[1]:
		var upper_age_ratio = age/age_ranges[1]
		ratios.append(["young_caucasian_"+gender,1])
		ratios.append(["middleage_caucasian_"+gender,upper_age_ratio])
	else:
		var upper_age_ratio = (age-age_ranges[1])/(age_ranges[2]-age_ranges[1])
		ratios.append(["middleage_caucasian_"+gender,1])
		ratios.append(["old_caucasian_"+gender,upper_age_ratio])
		
	return ratios
	


func multiply_arrays(array1:Array,array2:Array):
	if not array1.size() == array2.size():
		printerr("cant multiply arrays of different lengths")
		return null
	else:
		var output = []
		for i in array1.size():
			output.append(array1[i] * array2[i])
		return output

func set_shapekeys(shapekey_values:Dictionary):
	#print("setting shapekeys")
	#print(shapekey_values)
	for sk_name in shapekey_values:
		if sk_name == "age":
			update_skin_texture()
	humanizer.set_targets(shapekey_values)
	update_character()

#smooth zoom, so nice wow
func _on_zoom_slider_value_changed(value):
	var invr_value = 1-value
	%Camera3D.size = ((zoom_out_size-zoom_in_size) * invr_value) + zoom_in_size
	if invr_value < zoom_mid_ratio:
		%Camera3D.v_offset = ((zoom_mid_offset-zoom_in_offset) * (invr_value/zoom_mid_ratio)) + zoom_in_offset
	else:
		%Camera3D.v_offset = ((zoom_out_offset-zoom_mid_offset) * ((invr_value-zoom_mid_ratio)/(1-zoom_mid_ratio))) + zoom_mid_offset
	
	
func _on_next_pressed():
	var save_material = StandardMaterial3D.new()
	#save_material.albedo_color = skin_shader.get_shader_parameter("albedo")
	var save_texture_image = Image.create(2**11,2**11,true,Image.FORMAT_RGB8)
	var ratios = get_skin_color_ratios()
	var textures = []
	#for tex in skin_shader.get_shader_parameter("skin_textures"):
		#textures.append(tex.get_image())
	for x in save_texture_image.get_width():
		for y in save_texture_image.get_height():
			var color = Color.BLACK
			for r in ratios.size():
				if ratios[r] > 0.0:
					color += textures[r].get_pixel(x,y) * ratios[r]
			save_texture_image.set_pixel(x,y,color)
	
	save_texture_image.generate_mipmaps()
	save_material.albedo_texture = ImageTexture.create_from_image(save_texture_image)
	humanizer.get_node("DefaultBody").set_surface_override_material(0,save_material)
	humanizer.set_component_state(true,&'main_collider')
	## bake to merge mesh textures and surfaces
	#known weirdness when saving to path that already exists, delete it early when over-writing
	delete_directory(humanizer.save_path)
	humanizer.save_human_scene()
	get_tree().change_scene_to_file("res://test_world.tscn")


func _on_rotate_slider_value_changed(value: float) -> void:
	%Platform.rotation.y = value/100 * (4*PI)


static func add_label(text:String,node:Node)->Label:
	var label = Label.new()
	label.text = text
	node.add_child(label)
	return label

static func add_option_meta(text:String,meta,options:OptionButton,icon:Texture2D=null):
	var option_id = options.item_count
	options.add_item(text)
	if icon != null:
		options.set_item_icon(option_id,icon)
	options.set_item_metadata(option_id,meta)

static func get_option_text(options:OptionButton)->String:
	return options.get_item_text(options.get_selected_id())

func get_gender()->int:
	if get_option_text(%GenderOptions) == "Male":
		return 1
	return 0

func equipment_selected(index:int,options:OptionButton)->void:
	var texture_key = options.get_selected_metadata() # [equip_id,texture_id]
	if texture_key is StringName: #texture key is slot name
		var curr_equip = humanizer.human_config.get_equipment_in_slot(texture_key)
		humanizer.remove_equipment(curr_equip)
		return
	var equip = HumanizerEquipment.new(texture_key[0],texture_key[1])
	humanizer.add_equipment(equip)

func _on_gender_options_item_selected(index: int) -> void:
	set_shapekeys({gender=get_gender()})
	update_skin_texture()

func _on_skin_color_picker_color_changed(color: Color) -> void:
	update_skin_texture()

func _on_eye_color_picker_color_changed(color: Color) -> void:
	humanizer.set_eye_color(color)

func _on_hair_color_picker_color_changed(color: Color) -> void:
	humanizer.set_hair_color(color)

func _on_hair_type_select_item_selected(index: int) -> void:
	var hair_id = %HairTypeSelect.get_selected_metadata()
	if hair_id == null:
		humanizer.clear_body_part("Hair")
	else:
		humanizer.add_equipment(HumanizerEquipment.new(hair_id))

func _on_eyebrow_type_select_pressed() -> void:
	#print(eyebrow_menu_options[option_id])
	var eyebrow_id = %EyebrowTypeSelect.get_selected_metadata()
	humanizer.add_equipment(HumanizerEquipment.new(eyebrow_id))
	eyebrow_id = eyebrow_id.replace("Right","Left")
	humanizer.add_equipment(HumanizerEquipment.new(eyebrow_id))

func _on_eyelash_type_select_item_selected(index: int) -> void:
	var left_eyelash_name = "LeftEyelash"
	var right_eyelash_name = "RightEyelash"
	var material_name = "eyelashes04" #false lashes
	if index < 2:
		material_name = "eyelashes0" + str(index+1) 
	else:
		left_eyelash_name = "LeftEyelash-False"
		right_eyelash_name = "RightEyelash-False"
	humanizer.add_equipment(HumanizerEquipment.new(left_eyelash_name,material_name))
	humanizer.add_equipment(HumanizerEquipment.new(right_eyelash_name,material_name))

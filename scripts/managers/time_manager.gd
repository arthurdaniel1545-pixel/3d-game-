extends Node

signal time_changed(minutes: float, day: int)
signal day_changed(day: int)
signal period_changed(period: String) # dawn, day, dusk, night
signal weather_changed(weather: String)

const MINUTES_PER_DAY := 1440.0
const GAME_MINUTES_PER_REAL_SECOND := 0.5 # 48 min/day real-time feel adjustable

var day: int = 1
var time_minutes: float = 480.0 # 08:00
var weather: String = "clear"
var temperature_c: float = 22.0

var current_period: String = "day"

var _weather_timer: float = 0.0
var _weather_interval: float = 300.0

func _ready() -> void:
	_update_period()

func _process(delta: float) -> void:
	var prev_day := day
	time_minutes += delta * GAME_MINUTES_PER_REAL_SECOND * 60.0
	if time_minutes >= MINUTES_PER_DAY:
		time_minutes = fmod(time_minutes, MINUTES_PER_DAY)
		day += 1
		day_changed.emit(day)
	if prev_day != day:
		day_changed.emit(day)
	_update_period()
	_update_weather(delta)
	_update_temperature()
	time_changed.emit(time_minutes, day)

func _update_period() -> void:
	var new_period := get_period_name()
	if new_period != current_period:
		current_period = new_period
		period_changed.emit(current_period)

func _update_weather(delta: float) -> void:
	_weather_timer += delta
	if _weather_timer >= _weather_interval:
		_weather_timer = 0.0
		_roll_weather()

func _roll_weather() -> void:
	var roll := randf()
	var new_weather := "clear"
	if roll < 0.55:
		new_weather = "clear"
	elif roll < 0.75:
		new_weather = "cloudy"
	elif roll < 0.9:
		new_weather = "rain"
	else:
		new_weather = "storm"
	if new_weather != weather:
		weather = new_weather
		weather_changed.emit(weather)

func _update_temperature() -> void:
	# Simple model: cooler at night, warmer midday, modified by weather
	var hour := time_minutes / 60.0
	var base := 18.0 + 8.0 * sin((hour - 6.0) / 24.0 * TAU)
	if weather == "rain":
		base -= 3.0
	elif weather == "storm":
		base -= 5.0
	elif weather == "cloudy":
		base -= 1.0
	temperature_c = base

func get_period_name() -> String:
	var hour := time_minutes / 60.0
	if hour >= 5.0 and hour < 7.0:
		return "dawn"
	elif hour >= 7.0 and hour < 18.0:
		return "day"
	elif hour >= 18.0 and hour < 20.0:
		return "dusk"
	else:
		return "night"

func get_time_string() -> String:
	var hour := int(time_minutes / 60.0) % 24
	var minute := int(fmod(time_minutes, 60.0))
	return "%02d:%02d" % [hour, minute]

func get_daylight_factor() -> float:
	# 0.0 = full dark, 1.0 = full day
	var hour := time_minutes / 60.0
	if hour >= 7.0 and hour < 18.0:
		return 1.0
	elif hour >= 5.0 and hour < 7.0:
		return inverse_lerp(5.0, 7.0, hour)
	elif hour >= 18.0 and hour < 20.0:
		return inverse_lerp(20.0, 18.0, hour)
	else:
		return 0.15

func is_night() -> bool:
	return current_period == "night" or current_period == "dusk"

func get_save_data() -> Dictionary:
	return {
		"day": day,
		"time_minutes": time_minutes,
		"weather": weather
	}

func load_save_data(data: Dictionary) -> void:
	day = int(data.get("day", 1))
	time_minutes = float(data.get("time_minutes", 480.0))
	weather = str(data.get("weather", "clear"))
	_update_period()
	class="sr-only">[Progress update: 2 tool calls returned — reviewed.]

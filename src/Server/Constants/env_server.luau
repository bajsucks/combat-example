return {
	prefix_prod = "prod_",
	prefix_dev = "dev_",
	version = 1, -- For implementing data conversion between incompatible data profiles. Does not wipe player data
	save_data_live = true,
	save_data_studio = true,

	replication_throttle = true,
	replication_throttle_speed = 1 / 30,

	conch_superuser_in_studio = true, -- Whether all players should get `super-user` conch permissions when running in Studio

	conch_superuser_any = true, -- DANGER WARNING SCARY do not turn on unless you know what you are doing! This will give `super-user` conch permissions to EVERYONE, even in LIVE
}

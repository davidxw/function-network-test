suffix=$1

func azure functionapp publish functionappl1-1-$suffix
func azure functionapp publish functionappl1-2-$suffix
func azure functionapp publish functionappl2-1-$suffix
func azure functionapp publish functionappl2-2-$suffix

func azure functionapp list-functions functionappl1-1-$suffix --show-keys
func azure functionapp list-functions functionappl1-2-$suffix --show-keys
func azure functionapp list-functions functionappl2-1-$suffix --show-keys
func azure functionapp list-functions functionappl2-2-$suffix --show-keys
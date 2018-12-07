import sys
from datetime import datetime,timedelta
from ete3 import NCBITaxa
from os import path,makedirs



def check_taxa_db_age(dbLocation,sqliteLoc):
    # if file doesn't exist, catch the error and run the update, as it will create the file.
    ncbi = NCBITaxa(sqliteLoc)

    try:
        filetime = datetime.fromtimestamp(path.getctime(dbLocation))
        one_month_ago = datetime.now() - timedelta(days=30)
        if filetime < one_month_ago:
            # File older than 1 month, update it:
            print('<> NCBITaxa Database older than 1 month, updating it <>')
            ncbi.update_taxonomy_database()
        else:
            print('<> NCBITaxa Database up to date <>')
    except:
        print("<> NCBITaxa Database didn't exist, downloading it <>")
        ncbi.update_taxonomy_database()


if len(sys.argv) == 3:
        check_taxa_db_age(sys.argv[1],sys.argv[2])
else:
        print("\n\nError in check_db_age.py arguments:")
        print("There should be 2 command line arguments (TaxaDB location and sqlite DB location)")
        print("Example:")
        print("python check_taxa_db_age.py /path/to/taxadump.gz /path/to/ncbiSqliteDB")

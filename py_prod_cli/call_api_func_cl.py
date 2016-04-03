from sys import argv
import pandas as pd
import api_function


script, start_row, end_row, data_file = argv


start_row = int(start_row)
end_row = int(end_row)


# file name, located in the working directory
file_name = "products_reviewed.csv"


# use pandas to read in the data
products = pd.read_csv(file_name)


'''
replace the "remove after loading" string ...
the string below, rm_str is in place just to be extra cautious about ...
leading zeros in the product id. So, to preserve the string format across ...
platforms, I include a string to remove upon loading
'''

rm_str = "remove after loading"
products['product_id'] = products['product_id'].replace(rm_str, "", regex=True)




# dictionary of AWS credentials
credentials = {'AWSAccessKeyId': "access_key",
               'AWSSecretAccessKey': "secret_key",
               'AssociateTag': "associate_tag"}



''' 
call the API, store the results, and return some summary info when its
done running
'''
results = api_function.aws_product_attrs_storage(products['product_id'],
                                                 credentials,
                                                 data_file,
                                                 start_row,
                                                 end_row)


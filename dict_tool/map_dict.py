import dict_master as dm
import sys

in_dict = sys.argv[1]
phone_list = sys.argv[2]
phone_map = sys.argv[3]
out_dict = sys.argv[4]

dict_inst = dm.DictMaster(phone_list)

dLex = dict_inst.loadDict(in_dict)

dLex_map = dict_inst.mapPhone(dLex, phone_map)

dict_inst.WriteDict(dLex_map, out_dict)
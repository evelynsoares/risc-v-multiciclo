import re
import os

def parse_mif(file_path):
    content_map = {}
    depth = 0
    width = 0
    try:
        with open(file_path, 'r') as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                if line.startswith("DEPTH"):
                    depth = int(re.search(r"DEPTH\s*=\s*(\d+);", line).group(1))
                elif line.startswith("WIDTH"):
                    width = int(re.search(r"WIDTH\s*=\s*(\d+);", line).group(1))
                elif re.match(r"^[0-9a-fA-F]+ : [0-9a-fA-F]+;", line):
                    # Regex to capture address and data, ignoring comments
                    match = re.match(r"^\s*([0-9a-fA-F]+)\s*:\s*([0-9a-fA-F]+);.*$", line)
                    if match:
                        address = int(match.group(1), 16)
                        data = match.group(2)
                        content_map[address] = data
                    else:
                        print(f"DEBUG: Linha não corresponde ao padrão (ignorado): {file_path}:{line_num}: {line}")
                elif line.startswith("END;"):
                    break # Stop parsing after END;
    except FileNotFoundError:
        print(f"Erro: Arquivo não encontrado em {file_path}")
        return {}, 0, 0
    except Exception as e:
        print(f"Erro ao analisar {file_path}: {e}")
        return {}, 0, 0
    return content_map, depth, width

def combine_mifs(text_mif_path, data_mif_path, output_mif_path):
    quartus_ip_depth = 2048 # Depth for the Quartus IP memory block
    quartus_ip_width = 32

    text_content_map, text_original_depth, text_original_width = parse_mif(text_mif_path)
    data_content_map, data_original_depth, data_original_width = parse_mif(data_mif_path)

    if not text_content_map and not data_content_map:
        print("Aviso: Nenhum conteúdo encontrado nos arquivos .mif de texto ou dados. Gerando arquivo com DEFAULT_VALUE.")
        text_actual_depth = 0
        data_actual_depth = 0
    else:
        text_actual_depth = max(text_content_map.keys()) + 1 if text_content_map else 0
        data_actual_depth = max(data_content_map.keys()) + 1 if data_content_map else 0
    
    combined_content = {}
    current_unified_address = 0

    # Add text content, remapping addresses to start from 0
    for address in sorted(text_content_map.keys()):
        # We need to check if this address will fit within the Quartus IP depth
        if current_unified_address < quartus_ip_depth:
            combined_content[current_unified_address] = text_content_map[address]
            current_unified_address += 1
        else:
            print(f"Aviso: Endereço de instrução {hex(address)} excede a profundidade da memória unificada ({quartus_ip_depth}). Conteúdo truncado.")
            break

    for address in sorted(data_content_map.keys()):
        if current_unified_address < quartus_ip_depth:
            combined_content[current_unified_address] = data_content_map[address]
            current_unified_address += 1
        else:
            print(f"Aviso: Endereço de dado {hex(address)} excede a profundidade da memória unificada ({quartus_ip_depth}). Conteúdo truncado.")
            break

    # Determine the actual depth needed for the combined content
    combined_actual_depth = max(combined_content.keys()) + 1 if combined_content else 0

    # Ensure the depth of the output MIF is at least the Quartus IP depth
    output_depth = max(quartus_ip_depth, combined_actual_depth)

    # Write the combined MIF file
    try:
        with open(output_mif_path, 'w') as f:
            f.write(f"DEPTH = {output_depth};\n")
            f.write(f"WIDTH = {quartus_ip_width};\n")
            f.write("ADDRESS_RADIX = HEX;\n")
            f.write("DATA_RADIX = HEX;\n")
            f.write("CONTENT BEGIN\n")

            # Write actual content
            for address in range(output_depth):
                data = combined_content.get(address, "00000000") # Default to 00000000 if address not found
                f.write(f"  {address:08x} : {data};\n")

            f.write("END;\n")
        print(f"Arquivo unificado {output_mif_path} criado com sucesso.")
        print(f"Profundidade combinada real: {combined_actual_depth}")
        print(f"Profundidade do arquivo MIF de saída: {output_depth}")
    except Exception as e:
        print(f"Erro ao escrever o arquivo unificado: {e}")

# Define file paths
script_dir = os.path.dirname(__file__) if '__file__' in locals() else os.getcwd()
text_mif_file = os.path.join(script_dir, "de1_text.mif")
data_mif_file = os.path.join(script_dir, "de1_data.mif")
output_mif_file = os.path.join(script_dir, "de1_unified.mif")

# Execute the combination
combine_mifs(text_mif_file, data_mif_file, output_mif_file)
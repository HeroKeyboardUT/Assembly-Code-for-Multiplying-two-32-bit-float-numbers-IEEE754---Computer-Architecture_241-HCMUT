.include "macro.mac"

# Định nghĩa các biến dữ liệu
.data
dulieu1: .space 4             # Dành không gian để lưu số thực đầu tiên (4 byte)
dulieu2: .space 4             # Dành không gian để lưu số thực thứ hai (4 byte)
tenfile: .asciiz "FLOAT2.BIN" # Tên file chứa dữ liệu nhị phân
fdescr: .word 0               # Lưu file descriptor sau khi mở file
str_dl1: .asciiz "So thuc 1 = "  # Chuỗi hiển thị cho số thực đầu tiên
str_dl2: .asciiz "So thuc 2 = "  # Chuỗi hiển thị cho số thực thứ hai
overflow_text: .asciiz "Xay ra Overflow"  # Thông báo khi xảy ra tràn số
underflow_text: .asciiz "Xay ra Underflow"  # Thông báo khi xảy ra thiếu số
str_kq: .asciiz "Ket qua (So thuc) = "  # Chuỗi hiển thị cho kết quả
dulieukq: .space 4           # Không gian lưu kết quả (4 byte)
newline: .asciiz "\n"        # Ký tự xuống dòng

.text
######################################################################################
############                          Main                      ######################		
######################################################################################

main:
    # Sử dụng macro để mở file
    open_file_to_read tenfile, fdescr  # Mở file để đọc với tên "tenfile" và lưu mô tả file vào "fdescr"

    # Đọc số thực đầu tiên từ file
    read_file fdescr, dulieu1, 4       # Đọc 4 byte (32-bit float) đầu tiên vào "dulieu1"

    # Đọc số thực thứ hai từ file
    read_file fdescr, dulieu2, 4       # Đọc 4 byte (32-bit float) tiếp theo vào "dulieu2"

######################################################################################  
###############        Xuất giá trị 2 dữ liệu ra màn hình      #######################  
######################################################################################

    # Xuất giá trị dulieu1 và dulieu2 ra màn hình
    print_string_with_result str_dl1, dulieu1   # Xuất "So thuc 1 = <giá trị dulieu1>"
    print_newline                                # Xuống dòng
    print_string_with_result str_dl2, dulieu2   # Xuất "So thuc 2 = <giá trị dulieu2>"
    print_newline                                # Xuống dòng

######################################################################################  
#########   Tách số thực 1 thành các thành phần và chứa vào thanh ghi        #########  
#########   $t1 : 1 bit dấu              $t2: 8 bit Exponent                 #########  
#########   $t3: 23 bit Fraction                                             #########  
######################################################################################

    # Tách số thực đầu tiên (dulieu1)
    lw $t0, dulieu1              # Đọc giá trị của dulieu1 vào thanh ghi $t0
    srl $t1, $t0, 31             # Lấy bit dấu bằng cách dịch phải 31 bit, lưu vào $t1
    andi $t2, $t0, 0x7F800000    # AND với 0x7F800000 để lấy 8 bit exponent
    srl $t2, $t2, 23             # Dịch phải 23 bit để lấy giá trị exponent thực sự
    andi $t3, $t0, 0x7FFFFF      # AND với 0x7FFFFF để lấy 23 bit Fraction
    subi $t2, $t2, 127           # Điều chỉnh bias của exponent bằng cách trừ đi 127

    beqz $t0, BaseCase0          # Nếu giá trị $t0 bằng 0, nhảy đến BaseCase0 (xử lý trường hợp đặc biệt)

######################################################################################  
#########   Tách số thực 2 thành các thành phần và chứa vào thanh ghi        #########  
#########   $t4 : 1 bit dấu              $t5: 8 bit Exponent                 #########  
#########   $t6: 23 bit Fraction                                             #########  
######################################################################################

    # Tách số thực thứ hai (dulieu2)
    lw $t0, dulieu2              # Đọc giá trị của dulieu2 vào thanh ghi $t0
    srl $t4, $t0, 31             # Lấy bit dấu bằng cách dịch phải 31 bit, lưu vào $t4
    andi $t5, $t0, 0x7F800000    # AND với 0x7F800000 để lấy 8 bit exponent
    srl $t5, $t5, 23             # Dịch phải 23 bit để lấy giá trị exponent thực sự
    andi $t6, $t0, 0x7FFFFF      # AND với 0x7FFFFF để lấy 23 bit Fraction
    subi $t5, $t5, 127           # Điều chỉnh bias của exponent bằng cách trừ đi 127

    beqz $t0, BaseCase0          # Nếu giá trị $t0 bằng 0, nhảy đến BaseCase0 (xử lý trường hợp đặc biệt)

######################################################################################  
###############         XỬ LÝ BIT DẤU TRONG 2 THANH GHI $t1 VÀ $t4       #############  
######################################################################################

    # Gọi hàm tính toán dấu
    move $a0, $t1                # Truyền bit dấu của số thực 1 vào $a0
    move $a1, $t4                # Truyền bit dấu của số thực 2 vào $a1
    jal TinhToanDau              # Gọi hàm tính toán dấu
    move $t7, $v0                # Lưu kết quả dấu vào $t7

######################################################################################  
###############       XỬ LÝ BIT EXPONENT TRONG 2 THANH GHI $t2 VÀ $t5    #############  
######################################################################################

    # Gọi hàm tính toán exponent
    move $a0, $t2                # Truyền exponent của số thực 1 vào $a0
    move $a1, $t5                # Truyền exponent của số thực 2 vào $a1
    jal TinhToanExponent         # Gọi hàm tính toán exponent
    move $t8, $v0                # Lưu kết quả exponent vào $t8

######################################################################################  
###############       XỬ LÝ BIT FRACTION TRONG 2 THANH GHI $t3 VÀ $t6    #############  
######################################################################################

    # Gọi hàm tính toán fraction
    move $a0, $t3                # Truyền fraction của số thực 1 vào $a0
    move $a1, $t6                # Truyền fraction của số thực 2 vào $a1
    move $a2, $t8                # Truyền exponent đã tính toán vào $a2
    jal TinhToanFraction         # Gọi hàm tính toán fraction
    move $t9, $v0                # Lưu kết quả fraction vào $t9
    move $t8, $v1                # Cập nhật exponent đã chuẩn hóa vào $t8

######################################################################################  
####################        Ghép kết quả thành số thực       #########################  
######################################################################################

    # Ghép thành số thực IEEE-754
    move $a0, $t7                # Truyền bit dấu vào $a0
    move $a1, $t8                # Truyền exponent vào $a1
    move $a2, $t9                # Truyền fraction vào $a2
    jal GhepThanhSoThuc          # Gọi hàm ghép thành số thực IEEE-754

    # Lưu kết quả từ hàm trả về vào biến "dulieukq"
    sw $v0, dulieukq

    # In kết quả cuối cùng
    print_string_with_result str_kq, dulieukq  # Xuất "Ket qua = <giá trị dulieukq>"

    # Đóng file
    close_file fdescr            # Đóng file đã mở

#--------------------------  
    # Kết thúc chương trình
    li $v0, 10                   # Syscall 10: Thoát chương trình
    syscall                      # Thực hiện thoát chương trình
    
##################################################################################################  
#-----------------------            Phần định nghĩa các hàm         -----------------------------#
##################################################################################################

#-------------------------------------------------------------------------------------------------
# Hàm: Tính toán dấu
#-------------------------------------------------------------------------------------------------
# Đầu vào:
#   $a0 - Bit dấu của số thực đầu tiên
#   $a1 - Bit dấu của số thực thứ hai
#-------------------------------------------------------------------------------------------------
# Đầu ra:
#   $v0 - Bit dấu của kết quả (1 nếu khác dấu, 0 nếu cùng dấu)
#-------------------------------------------------------------------------------------------------
TinhToanDau:
    xor $v0, $a0, $a1        # XOR hai bit dấu để tính dấu của kết quả
    jr $ra                   # Quay lại hàm gọi

#-------------------------------------------------------------------------------------------------
# Hàm: Tính toán exponent
#-------------------------------------------------------------------------------------------------
# Đầu vào:
#   $a0 - Exponent của số thực đầu tiên
#   $a1 - Exponent của số thực thứ hai
#-------------------------------------------------------------------------------------------------
# Đầu ra:
#   $v0 - Exponent đã tính toán (bao gồm bias)
#-------------------------------------------------------------------------------------------------
TinhToanExponent:
    add $v0, $a0, $a1        # Cộng hai giá trị exponent
    addi $v0, $v0, 127       # Thêm bias (127) vào kết quả
    
    li $t1, 255
    bge  $v0, $t1, overflow   # Kiểm tra Overflow
    li $t1, 0
    ble $v0, $t1, underflow  # Kiểm tra Underflow
    jr $ra                   # Quay lại hàm gọi

#-------------------------------------------------------------------------------------------------
# Hàm: Tính toán Fraction
#-------------------------------------------------------------------------------------------------
# Đầu vào:
#   $a0 - Fraction của số thực đầu tiên
#   $a1 - Fraction của số thực thứ hai
#   $a2 - Exponent hiện tại
#-------------------------------------------------------------------------------------------------
# Đầu ra:
#   $v0 - Fraction đã chuẩn hóa
#   $v1 - Exponent đã chuẩn hóa
#-------------------------------------------------------------------------------------------------
TinhToanFraction:
    ori $a0, $a0, 0x800000   # Thêm bit ẩn (1) vào Fraction của số đầu tiên
    ori $a1, $a1, 0x800000   # Thêm bit ẩn (1) vào Fraction của số thứ hai

    multu $a0, $a1           # Nhân hai giá trị Fraction không dấu
    mfhi $t0                 # Lấy phần cao (HI) của kết quả nhân
    mflo $t1                 # Lấy phần thấp (LO) của kết quả nhân

    sll $t0, $t0, 16         # Dịch trái phần cao 16 bit
    srl $t1, $t1, 16         # Dịch phải phần thấp 16 bit
    or $t0, $t0, $t1         # Ghép phần cao và thấp thành Fraction 32-bit

    srl $t0, $t0, 7          # Dịch phải 7 bit để chuẩn hóa Fraction thành 25 bit

    srl $t1, $t0, 23         # Kiểm tra bit ngoài để xác định chuẩn hóa
    subi $t1, $t1, 1         # Trừ 1 để kiểm tra bit
    beqz $t1, NotNormalize   # Nếu không cần chuẩn hóa, nhảy tới `NotNormalize`

    addi $a2, $a2, 1         # Tăng giá trị Exponent nếu cần chuẩn hóa
    srl $t0, $t0, 1          # Dịch phải Fraction 1 bit để chuẩn hóa

    li $t1, 255
    bge  $a2, $t1, overflow   # Kiểm tra Overflow
    li $t1, 0
    ble $a2, $t1, underflow  # Kiểm tra Underflow

NotNormalize:
    andi $t0, $t0, 0x7FFFFF  # Giữ lại 23 bit Fraction
    move $v0, $t0            # Lưu Fraction chuẩn hóa vào $v0
    move $v1, $a2            # Lưu Exponent chuẩn hóa vào $v1
    jr $ra                   # Quay lại hàm gọi

#-------------------------------------------------------------------------------------------------
# Hàm: Ghép thành số thực IEEE-754
#-------------------------------------------------------------------------------------------------
# Đầu vào:
#   $a0 - Bit dấu
#   $a1 - Exponent
#   $a2 - Fraction
#-------------------------------------------------------------------------------------------------
# Đầu ra:
#   $v0 - 32 bit biểu diễn số thực
#-------------------------------------------------------------------------------------------------
GhepThanhSoThuc:
    sll $t0, $a0, 31         # Dịch trái bit dấu vào vị trí bit cao nhất
    sll $t1, $a1, 23         # Dịch trái Exponent vào vị trí của nó
    or $v0, $a2, $t1         # Ghép Fraction và Exponent
    or $v0, $v0, $t0         # Ghép với bit dấu
    jr $ra                   # Quay lại hàm gọi
    
   
    
#------------------------------------------------------------------------------------#   
#--------------------        Hàm xử lí nếu có số thực bằng 0          ---------------# 
#------------------------------------------------------------------------------------#  
BaseCase0:
    # Xử lý trường hợp nhân với 0, ta sẽ trả về kết quả là 0.0
    li $t0,0
    sw $t0, dulieukq
    print_string_with_result str_kq, dulieukq

    li $v0, 10               # Syscall 10: Thoát chương trình
    syscall                  # Thực hiện thoát chương trình

#------------------------------------------------------------------------------------#  
#------------------        Xử lý trường hợp Overflow và Underflow       -------------# 
#------------------------------------------------------------------------------------#  
overflow:
    # Trường hợp Overflow (Exponent vượt quá giá trị lớn nhất cho phép)
    print_string overflow_text # In thông báo "Xảy ra Overflow"
    li $v0, 10                 # Syscall 10: Thoát chương trình
    syscall                    # Thực hiện thoát chương trình

underflow:
    # Trường hợp Underflow (Exponent nhỏ hơn giá trị nhỏ nhất cho phép)
    print_string underflow_text # In thông báo "Xảy ra Underflow"
    li $v0, 10                  # Syscall 10: Thoát chương trình
    syscall                     # Thực hiện thoát chương trình

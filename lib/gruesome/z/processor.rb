# The Z-Machine processor unit will execute a stream of Instructions

require_relative 'instruction'
require_relative 'opcode'
require_relative 'header'
require_relative 'zscii'

module Gruesome
	module Z
		class Processor
			def initialize(memory)
				@memory = memory
				@header = Header.new(@memory.contents)
			end

			def execute(instruction)
				case instruction.opcode
				when Opcode::JUMP
					@memory.program_counter += unsigned_to_signed(instruction.operands[0])
					@memory.program_counter -= 2
				when Opcode::JE
					result = instruction.operands[1..-1].inject(false) { |result, element|
						result | (instruction.operands[0] == element)
					}
					if (result and instruction.branch_on) or (!result and !instruction.branch_on)
						@memory.program_counter += unsigned_to_signed(instruction.branch_to)
						@memory.program_counter -= 2
					end
				when Opcode::JG
					result = unsigned_to_signed(instruction.operands[0]) > unsigned_to_signed(instruction.operands[1])
					if (result and instruction.branch_on) or (!result and !instruction.branch_on)
						@memory.program_counter += unsigned_to_signed(instruction.branch_to)
						@memory.program_counter -= 2
					end
				when Opcode::JIN
					# XXX: JIN is an object instruction
				when Opcode::JL
					result = unsigned_to_signed(instruction.operands[0]) < unsigned_to_signed(instruction.operands[1])
					if (result and instruction.branch_on) or (!result and !instruction.branch_on)
						@memory.program_counter += unsigned_to_signed(instruction.branch_to)
						@memory.program_counter -= 2
					end
				when Opcode::PRINT
					print instruction.operands[0]
				when Opcode::PRINT_ADDR
					print ZSCII.translate(0, @header.version, @memory.force_readzstr(instruction.operands[0], 0)[1])
				when Opcode::PRINT_CHAR
					print ZSCII.translate(0, @header.version, [instruction.operands[0]])
				when Opcode::ADD
					@memory.writev(instruction.destination,
						unsigned_to_signed(instruction.operands[0]) + unsigned_to_signed(instruction.operands[1]))
				when Opcode::SUB
					@memory.writev(instruction.destination,
						unsigned_to_signed(instruction.operands[0]) - unsigned_to_signed(instruction.operands[1]))
				when Opcode::MUL
					@memory.writev(instruction.destination,
						unsigned_to_signed(instruction.operands[0]) * unsigned_to_signed(instruction.operands[1]))
				when Opcode::DIV
					result = unsigned_to_signed(instruction.operands[0]).to_f / unsigned_to_signed(instruction.operands[1]).to_f
					if result < 0
						result = -(result.abs.floor)
					else
						result = result.floor
					end
					@memory.writev(instruction.destination, result.to_i)
				when Opcode::MOD
					a = unsigned_to_signed(instruction.operands[0])
					b = unsigned_to_signed(instruction.operands[1])
					result = a.abs % b.abs
					if a < 0 
						result = -result
					end
					@memory.writev(instruction.destination, result.to_i)
				when Opcode::NOT
					@memory.writev(instruction.destination, ~(instruction.operands[0]))
				when Opcode::OR
					@memory.writev(instruction.destination, instruction.operands[0] | instruction.operands[1])
				when Opcode::AND
					@memory.writev(instruction.destination, instruction.operands[0] & instruction.operands[1])
				when Opcode::STORE
					@memory.writev(instruction.operands[0], instruction.operands[1])
				when Opcode::STOREB
					@memory.writeb(instruction.operands[0] + unsigned_to_signed(instruction.operands[1]), instruction.operands[2])
				when Opcode::STOREW
					@memory.writew(instruction.operands[0] + unsigned_to_signed(instruction.operands[1]), instruction.operands[2])
				end
			end

			def unsigned_to_signed(op)
				sign = op & 0x8000
				if sign != 0
					-(65536 - op)
				else
					op
				end
			end
			private :unsigned_to_signed
		end
	end
end

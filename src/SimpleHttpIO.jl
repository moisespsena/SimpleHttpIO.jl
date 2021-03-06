module SimpleHttpIO

export readlinebare,
       readlinestr,
       readlinebarestr,
       AbstractIOSocket,
       writeln,
       CRLF,
       AbstractIOSocket,
       IOSocket,
       readbyte,
       BYTE_TYPE,
       stop,
       LINE_READERS

const CRLF = "\r\n"
const N = Void
const N_TYPE = Type{Void}
const STR_TYPE = isdefined(:AbstractString)? AbstractString : String
const BYTE_TYPE = isdefined(:UInt8)? UInt8 : Uint8

abstract AbstractIOSocket

type IOSocket <: AbstractIOSocket
   io::IO
   env::Associative
end

IOSocket(io::IO; kwargs...) = IOSocket(io, Dict{Any, Any}(kwargs))


function writeln(io::AbstractIOSocket, args...)
    s = Base.write(io.io, args...)
    s2 = Base.write(io.io, CRLF.data)
    (isa(s, Integer) ? s : 0) + s2
end

Base.read{T}(io::AbstractIOSocket, t::Type{T}, bs::Int32) = Base.read(io.io, t , bs)

Base.readbytes(io::AbstractIOSocket, size::Integer=1024) = Base.read(io.io, BYTE_TYPE, size)
readbyte(io::AbstractIOSocket) = readbytes(io, 1)[1]
readline_(io::AbstractIOSocket) = begin
    buf = BYTE_TYPE[]
    last = N_TYPE

    while true
        b = read(io.io, BYTE_TYPE, 1)[1]
        push!(buf, b)

        if last == '\r' && b == '\n'
           break
        end

        last = b
    end
    buf
end

readlinestr(io::AbstractIOSocket) = UTF8String(readline_(io))
readlinebare(io::AbstractIOSocket) = readline_(io)[1:end-2]
Base.readline(io::AbstractIOSocket) = readline_(io)

readlinebarestr(io::AbstractIOSocket) = UTF8String(readlinebare(io))

const LINE_READERS = [:s => readlinestr, :s! => readlinebarestr,
                      :b => readline_, :b! => readlinebare]

type EachLineStopIterator <: Exception end

type EachLine
    stream::AbstractIOSocket
    reader::Function
    count::Integer
end

stop() = throw(EachLineStopIterator())

Base.eachline(stream::AbstractIOSocket, reader::Function=Base.readline) = EachLine(stream, reader, 0)
Base.eachline(stream::AbstractIOSocket, reader::Symbol=:b) = EachLine(stream, LINE_READERS[reader], 0)

Base.eachline(cb::Function, stream::AbstractIOSocket, reader::Function=Base.readline) = begin
    itr = Base.eachline(stream, reader)

    try
        for line in itr
            cb(itr, line)
        end
    catch e
        if !isa(e, EachLineStopIterator)
            rethrow()
        end
    end

    itr.count
end

Base.eachline(cb::Function, stream::AbstractIOSocket, reader::Symbol) = begin
    Base.eachline(cb, stream, LINE_READERS[reader])
end

Base.start(itr::EachLine) = (itr.count = 0; N)
Base.done(itr::EachLine, nada) = false

Base.next(itr::EachLine, nada) = begin
    itr.count += 1
    itr.reader(itr.stream), N
end

end

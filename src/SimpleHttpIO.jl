module SimpleHttpIO

export readline_bare,
       readline_str,
       readline_bare_str,
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

abstract AbstractIOSocket

type IOSocket <: AbstractIOSocket
   io::IO
   env::Associative
end

IOSocket(io::IO; kwargs...) = IOSocket(io, Dict{Any, Any}(kwargs))

if !isdefined(:UInt8)
    const BYTE_TYPE = Uint8
else
    const BYTE_TYPE = UInt8
end

function writeln(io::AbstractIOSocket, args...)
    s = Base.write(io.io, args...)
    s2 = Base.write(io.io, CRLF.data)
    (s != nothing ? s : 0) + s2
end

Base.read{T}(io::AbstractIOSocket, t::Type{T}, bs::Int32) = Base.read(io.io, t , bs)

Base.readbytes(io::AbstractIOSocket, size::Integer=1024) = Base.read(io.io, BYTE_TYPE, size)
readbyte(io::AbstractIOSocket) = readbytes(io, 1)[1]
readline_(io::AbstractIOSocket) = begin
    buf = BYTE_TYPE[]
    last = Nothing

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

readline_str(io::AbstractIOSocket) = UTF8String(readline_(io))
readline_bare(io::AbstractIOSocket) = readline_(io)[1:end-2]
Base.readline(io::AbstractIOSocket) = readline_(io)

readline_bare_str(io::AbstractIOSocket) = UTF8String(readline_bare(io))

const LINE_READERS = [:s => readline_str, :s! => readline_bare_str,
                      :b => readline_, :b! => readline_bare]

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

Base.start(itr::EachLine) = (itr.count = 0; nothing)
Base.done(itr::EachLine, nada) = false

Base.next(itr::EachLine, nada) = begin
    itr.count += 1
    itr.reader(itr.stream), nothing
end

end

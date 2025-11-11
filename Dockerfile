FROM golang:1.22-alpine AS build
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
ENV CGO_ENABLED=0
RUN go build -o /out/notesapi main.go

FROM gcr.io/distroless/static:nonroot
WORKDIR /app
COPY --from=build /out/notesapi /app/notesapi
COPY notatki.txt /app/notatki.txt
COPY logo.txt /app/logo.txt
ENV NOTES_PATH=/app/notatki.txt
EXPOSE 8040
USER nonroot:nonroot
ENTRYPOINT ["/app/notesapi"]

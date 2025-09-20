import * as React from "react"

export function Button({ className = "", children, ...props }) {
  return (
    <button
      className={`bg-blue-600 hover:bg-blue-700 text-white rounded-md transition duration-200 ${className}`}
      {...props}
    >
      {children}
    </button>
  )
}

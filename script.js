// Mobile Navigation Toggle
const hamburger = document.querySelector(".hamburger")
const navMenu = document.querySelector(".nav-menu")

if (hamburger && navMenu) {
  hamburger.addEventListener("click", () => {
    hamburger.classList.toggle("active")
    navMenu.classList.toggle("active")
  })

  // Close mobile menu when clicking on a link
  document.querySelectorAll(".nav-link").forEach((n) =>
    n.addEventListener("click", () => {
      hamburger.classList.remove("active")
      navMenu.classList.remove("active")
    }),
  )
}

// Smooth scrolling for anchor links
document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
  anchor.addEventListener("click", function (e) {
    e.preventDefault()
    const target = document.querySelector(this.getAttribute("href"))
    if (target) {
      target.scrollIntoView({
        behavior: "smooth",
        block: "start",
      })
    }
  })
})

// Navbar scroll effect
window.addEventListener("scroll", () => {
  const navbar = document.querySelector(".navbar")
  if (navbar) {
    if (window.scrollY > 100) {
      navbar.style.background = "rgba(255, 255, 255, 0.95)"
      navbar.style.backdropFilter = "blur(10px)"
    } else {
      navbar.style.background = "#fff"
      navbar.style.backdropFilter = "none"
    }
  }
})

// Contact Form Handling
const contactForm = document.getElementById("contactForm")
if (contactForm) {
  contactForm.addEventListener("submit", function (e) {
    e.preventDefault()

    // Get form data
    const formData = new FormData(this)
    const data = Object.fromEntries(formData)

    // Simple validation
    if (!data.name || !data.email || !data.service) {
      alert("Please fill in all required fields.")
      return
    }

    // Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(data.email)) {
      alert("Please enter a valid email address.")
      return
    }

    // Simulate form submission
    const submitButton = this.querySelector('button[type="submit"]')
    const originalText = submitButton.textContent

    submitButton.textContent = "Sending..."
    submitButton.disabled = true

    // Simulate API call
    setTimeout(() => {
      alert("Thank you for your message! We'll get back to you within 24 hours.")
      this.reset()
      submitButton.textContent = originalText
      submitButton.disabled = false
    }, 2000)
  })
}

// Animate elements on scroll
const observerOptions = {
  threshold: 0.1,
  rootMargin: "0px 0px -50px 0px",
}

const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      entry.target.style.opacity = "1"
      entry.target.style.transform = "translateY(0)"
    }
  })
}, observerOptions)

// Observe elements for animation
document.addEventListener("DOMContentLoaded", () => {
  const animateElements = document.querySelectorAll(
    ".feature-card, .service-card, .plan-card, .team-card, .story-card, .tip-card",
  )

  animateElements.forEach((el) => {
    el.style.opacity = "0"
    el.style.transform = "translateY(30px)"
    el.style.transition = "opacity 0.6s ease, transform 0.6s ease"
    observer.observe(el)
  })
})

// Counter animation for statistics
function animateCounter(element, target, duration = 2000) {
  let start = 0
  const increment = target / (duration / 16)

  const timer = setInterval(() => {
    start += increment
    if (start >= target) {
      element.textContent = target + (element.dataset.suffix || "")
      clearInterval(timer)
    } else {
      element.textContent = Math.floor(start) + (element.dataset.suffix || "")
    }
  }, 16)
}

// Initialize counters when they come into view
const counterObserver = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      const counter = entry.target
      const target = Number.parseInt(counter.dataset.target)
      animateCounter(counter, target)
      counterObserver.unobserve(counter)
    }
  })
})

document.addEventListener("DOMContentLoaded", () => {
  const counters = document.querySelectorAll(".stat-number")
  counters.forEach((counter) => {
    // Extract number from text content
    const text = counter.textContent
    const number = Number.parseInt(text.replace(/\D/g, ""))
    const suffix = text.replace(/\d/g, "")

    counter.dataset.target = number
    counter.dataset.suffix = suffix
    counter.textContent = "0" + suffix

    counterObserver.observe(counter)
  })
})

// Dropdown menu functionality
document.addEventListener("DOMContentLoaded", () => {
  const dropdowns = document.querySelectorAll(".dropdown")

  dropdowns.forEach((dropdown) => {
    const dropdownContent = dropdown.querySelector(".dropdown-content")

    dropdown.addEventListener("mouseenter", () => {
      dropdownContent.style.display = "block"
    })

    dropdown.addEventListener("mouseleave", () => {
      dropdownContent.style.display = "none"
    })
  })
})
